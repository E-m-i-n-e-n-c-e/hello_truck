import { Injectable, UnauthorizedException, BadRequestException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { PrismaService } from '../prisma/prisma.service';
import { ConfigService } from '@nestjs/config';
import * as crypto from 'crypto';

@Injectable()
export class AuthService {
  constructor(
    private prisma: PrismaService,
    private jwtService: JwtService,
    private configService: ConfigService,
  ) {}

  // Send OTP via MSG91 (this would be integrated with MSG91 API)
  async sendOtp(phoneNumber: string): Promise<{ success: boolean; message: string }> {
    // Validate phone number format
    if (!this.isValidPhoneNumber(phoneNumber)) {
      throw new BadRequestException('Invalid phone number format');
    }

    // Generate OTP
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const expiresAt = new Date(Date.now() + 30 * 1000); // OTP valid for 30 seconds

    // Store OTP in database
    await this.prisma.otpVerification.create({
      data: {
        phoneNumber,
        otp,
        expiresAt,
      },
    });

    // In a real implementation, you would call MSG91 API here
    // For now, we'll just log the OTP (in production, never log OTPs)
    console.log(`OTP for ${phoneNumber}: ${otp}`);

    return { 
      success: true, 
      message: 'OTP sent successfully' 
    };
  }

  // Verify OTP and create user if needed
  async verifyOtp(phoneNumber: string, otp: string): Promise<{ accessToken: string; refreshToken: string }> {
    // Find the most recent OTP for this phone number
    const otpVerification = await this.prisma.otpVerification.findFirst({
      where: {
        phoneNumber,
        verified: false,
        expiresAt: {
          gt: new Date(),
        },
      },
      orderBy: {
        createdAt: 'desc',
      },
    });

    if (!otpVerification || otpVerification.otp !== otp) {
      throw new UnauthorizedException('Invalid or expired OTP');
    }

    // Mark OTP as verified
    await this.prisma.otpVerification.update({
      where: { id: otpVerification.id },
      data: { verified: true },
    });

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
    return this.generateTokens(user.id);
  }

  // Generate access and refresh tokens
  async generateTokens(userId: string): Promise<{ accessToken: string; refreshToken: string }> {
    const [accessToken, refreshToken] = await Promise.all([
      this.jwtService.signAsync(
        { id: userId },
        {
          secret: this.configService.get<string>('JWT_SECRET'),
          expiresIn: '15m',
        },
      ),
      this.generateRefreshToken(userId),
    ]);

    return { accessToken, refreshToken };
  }

  // Generate a refresh token and store it
  async generateRefreshToken(userId: string): Promise<string> {
    const refreshToken = crypto.randomBytes(64).toString('hex');
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 30); // Refresh token valid for 30 days

    // Store refresh token
    await this.prisma.session.create({
      data: {
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
      where: { id: session.id },
    });

    // Generate new tokens
    return this.generateTokens(session.userId);
  }

  // Logout - invalidate refresh token
  async logout(refreshToken: string): Promise<{ success: boolean }> {
    await this.prisma.session.deleteMany({
      where: { refreshToken },
    });

    return { success: true };
  }

  // Validate phone number format
  private isValidPhoneNumber(phoneNumber: string): boolean {
    // Basic validation - can be enhanced based on requirements
    return /^\+?[1-9]\d{9,14}$/.test(phoneNumber);
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
  // Validate refresh token
  async validateRefreshToken(refreshToken: string): Promise<any> {
    const session = await this.prisma.session.findUnique({
      where: { refreshToken },
      include: { user: true },
    });

    if (!session || session.expiresAt < new Date()) {
      throw new UnauthorizedException('Invalid or expired refresh token');
    }

    return session.user;
  }
}
