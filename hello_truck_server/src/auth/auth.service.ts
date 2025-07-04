import { Injectable, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { PrismaService } from '../prisma/prisma.service';
import { ConfigService } from '@nestjs/config';
import { OtpService } from '../otp/otp.service';
import * as crypto from 'crypto';
import { VerifyOtpDto } from './dtos/verify-otp.dto';
import { User } from '@prisma/client';

@Injectable()
export class AuthService {
  constructor(
    private prisma: PrismaService,
    private jwtService: JwtService,
    private configService: ConfigService,
    private otpService: OtpService,
  ) {}

  async sendOtp(phoneNumber: string): Promise<{ success: boolean; message: string }> {
    return this.otpService.sendOtp(phoneNumber);
  }

  async verifyOtp(verifyOtpDto: VerifyOtpDto): Promise<{ accessToken: string; refreshToken: string }> {
    const { phoneNumber, otp, existingRefreshToken } = verifyOtpDto;
    // Verify OTP using OTP service
    await this.otpService.verifyOtp(phoneNumber, otp);

    // Find or create user
    let user = await this.prisma.user.findUnique({
      where: { phoneNumber },
    });

    if (!user) {
      user = await this.prisma.user.create({
        data: { phoneNumber },
      });
    }

    // Generate tokens
    const accessToken = await this.generateAccessToken(user);
    const newRefreshToken = await this.generateRefreshToken(user.id,existingRefreshToken);
    return { accessToken, refreshToken: newRefreshToken };
  }

  // Generate access and refresh tokens
  async generateAccessToken(user: User): Promise<string> {
    const accessToken = await this.jwtService.signAsync(
      { userId: user.id, userName: user.userName, phoneNumber: user.phoneNumber },
      {
        secret: this.configService.get<string>('JWT_SECRET'),
        expiresIn: '15m',
      },
    );

    return accessToken;
  }

  // Generate a refresh token and store it
  async generateRefreshToken(userId: string, existingRefreshToken?: string): Promise<string> {
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 30); // valid for 30 days
  
    // Generate a new refresh token if one is not provided
    const refreshToken = existingRefreshToken ?? crypto.randomBytes(64).toString('hex');
  
    await this.prisma.session.upsert({
      where: {
        refreshToken, // must be unique in your Prisma schema
      },
      update: {
        expiresAt, // just update expiration if token already exists
      },
      create: {
        userId,
        refreshToken,
        expiresAt,
      },
    });
  
    return refreshToken;
  }

  // Refresh access token using refresh token
  async refreshAccessToken(refreshToken: string): Promise<{ accessToken: string; refreshToken: string }> {
    // Find session with this refresh token
    const session = await this.prisma.session.findUnique({
      where: { refreshToken },
      include: { user: true },
    });

    if (!session || session.expiresAt < new Date()) {
      throw new UnauthorizedException('Invalid or expired refresh token');
    }

    // Delete the used refresh token
    await this.prisma.session.delete({
      where: { id: session.id, },
    });

    // Generate new tokens
    const accessToken = await this.generateAccessToken(session.user);
    const newRefreshToken = await this.generateRefreshToken(session.userId);
    return { accessToken, refreshToken: newRefreshToken };
  }

  // Logout - invalidate refresh token
  async logout(refreshToken: string): Promise<{ success: boolean }> {
    await this.prisma.session.deleteMany({
      where: { refreshToken },
    });

    return { success: true };
  }
}
