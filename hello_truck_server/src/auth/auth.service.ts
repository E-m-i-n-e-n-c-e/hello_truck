import { Injectable, UnauthorizedException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { OtpService } from '../otp/otp.service';
import { VerifyOtpDto } from './dtos/verify-otp.dto';
import { TokenService } from '../token/token.service';

@Injectable()
export class AuthService {
  constructor(
    private prisma: PrismaService,
    private otpService: OtpService,
    private tokenService: TokenService,
  ) {}

  async sendOtp(phoneNumber: string): Promise<{ success: boolean; message: string }> {
    return this.otpService.sendOtp(phoneNumber);
  }

  async verifyOtp(verifyOtpDto: VerifyOtpDto): Promise<{ accessToken: string; refreshToken: string }> {
    const { phoneNumber, otp, staleRefreshToken } = verifyOtpDto;

    await this.otpService.verifyOtp(phoneNumber, otp);

    let user = await this.prisma.user.findUnique({
      where: { phoneNumber },
    });

    if (!user) {
      user = await this.prisma.user.create({
        data: { phoneNumber },
      });
    }

    const accessToken = await this.tokenService.generateAccessToken(user);
    const newRefreshToken = await this.tokenService.generateRefreshToken(user.id, staleRefreshToken);
    return { accessToken, refreshToken: newRefreshToken };
  }

  async logout(refreshToken: string): Promise<{ success: boolean }> {
    if (!refreshToken || !refreshToken.includes('.')) {
      throw new UnauthorizedException('Invalid refresh token format');
    }

    const [sessionId] = refreshToken.split('.', 2);
    
    await this.prisma.session.deleteMany({
      where: { id: sessionId },
    });

    return { success: true };
  }
}
