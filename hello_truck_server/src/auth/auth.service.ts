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
    const { phoneNumber, otp, staleRefreshToken } = verifyOtpDto;
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
    const newRefreshToken = await this.generateRefreshToken(user.id, staleRefreshToken);
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
  async generateRefreshToken(userId: string, staleRefreshToken?: string): Promise<string> {
    const newRefreshToken = crypto.randomBytes(64).toString('hex');
    const expiresAt = new Date(Date.now() + 1000 * 60 * 60 * 24 * 30); // 30 days
  
    // If an stale refresh token is provided, try to delete it first
    if (staleRefreshToken) {
      await this.prisma.session.deleteMany({
        where: { refreshToken: staleRefreshToken },
      });
    }
    // Create a new session
    await this.prisma.session.create({
      data: {
        userId,
        refreshToken: newRefreshToken,
        expiresAt,
      },
    });
  
    return newRefreshToken;
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

  // Validate JWT token
  async validateAccessToken(token: string): Promise<any> {  
    try {
      const payload = this.jwtService.verify(token, {
        secret: this.configService.get<string>('JWT_SECRET'),
      });
      return await this.prisma.user.findUnique({ where: { id: payload.id } });
    } catch (error) {
      throw new UnauthorizedException('Invalid token');
    }
  }
}
