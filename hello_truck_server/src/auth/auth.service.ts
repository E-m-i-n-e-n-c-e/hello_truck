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
    const newToken = crypto.randomBytes(64).toString('hex');
    const expiresAt = new Date(Date.now() + 1000 * 60 * 60 * 24 * 30); // 30 days
  
    // If a stale refresh token is provided, delete the session
    if (staleRefreshToken) {
      await this.prisma.session.delete({
        where: { id: staleRefreshToken.split('.')[0] },
      });
    }
    
    // Create a new session
    const session = await this.prisma.session.create({
      data: {
        userId,
        token: newToken,
        expiresAt,
      },
    });
  
    return `${session.id}.${newToken}`;
  }

  // Refresh access token using refresh token
  async refreshAccessToken(refreshToken: string): Promise<{ accessToken: string; refreshToken: string }> {
    if (!refreshToken || !refreshToken.includes('.')) {
      throw new UnauthorizedException('Invalid refresh token format');
    }

    const [sessionId, tokenValue] = refreshToken.split('.');
    
    // Find session with this  sessionID
    const session = await this.prisma.session.findUnique({
      where: { id: sessionId },
      include: { user: true },
    });

    if (!session || session.expiresAt < new Date()) {
      throw new UnauthorizedException('Invalid or expired refresh token');
    }
    // Check if token matches current token or old token
    const isCurrentToken = session.token === tokenValue;
    const isOldToken = session.oldToken === tokenValue;

    if (isCurrentToken || isOldToken) {
      const newToken = crypto.randomBytes(64).toString('hex');
      
      // Update session with new token
      await this.prisma.session.update({
        where: { id: session.id },
        data: {
          token: newToken,
          ...(isCurrentToken && { oldToken: session.token }), // Only set oldToken if current token was used
          expiresAt: new Date(Date.now() + 1000 * 60 * 60 * 24 * 30), // Extend expiration by 30 days
        },
      });

      // Generate new access token
      const accessToken = await this.generateAccessToken(session.user);
      return { 
        accessToken,
        refreshToken: `${session.id}.${newToken}`
      };
    } 
    // Neither current nor old token matches - potential security breach
    await this.prisma.session.delete({
      where: { id: session.id },
    });
    throw new UnauthorizedException('Invalid refresh token - session terminated');
  }

  // Logout - invalidate session
  async logout(refreshToken: string): Promise<{ success: boolean }> {
    if (!refreshToken || !refreshToken.includes('.')) {
      throw new UnauthorizedException('Invalid refresh token format');
    }

    const [sessionId] = refreshToken.split('.');
    
    await this.prisma.session.delete({
      where: { id: sessionId },
    });

    return { success: true };
  }

  // Validate JWT token
  async validateAccessToken(token: string): Promise<any> {  
    try {
      const payload = this.jwtService.verify(token, {
        secret: this.configService.get<string>('JWT_SECRET'),
      });
      return await this.prisma.user.findUnique({ where: { id: payload.userId } });
    } catch (error) {
      throw new UnauthorizedException('Invalid token');
    }
  }

  // Validate refresh token
  async validateRefreshToken(refreshToken: string): Promise<any> {
    if (!refreshToken || !refreshToken.includes('.')) {
      throw new UnauthorizedException('Invalid refresh token format');
    }

    const [sessionId, tokenValue] = refreshToken.split('.');
    
    const session = await this.prisma.session.findUnique({
      where: { id: sessionId },
      include: { user: true },
    });

    if (!session || session.expiresAt < new Date()) {
      throw new UnauthorizedException('Invalid or expired refresh token');
    }

    // Check if token matches either current or old token
    if (session.token !== tokenValue && session.oldToken !== tokenValue) {
      // Security breach - delete the session
      await this.prisma.session.delete({
        where: { id: sessionId },
      });
      throw new UnauthorizedException('Invalid refresh token - session terminated');
    }

    return session.user;
  }
}
