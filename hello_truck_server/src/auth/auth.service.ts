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

  async sendCustomerOtp(phoneNumber: string): Promise<{ success: boolean; message: string }> {
    return this.otpService.sendOtp(phoneNumber);
  }

  async verifyCustomerOtp(verifyOtpDto: VerifyOtpDto): Promise<{ accessToken: string; refreshToken: string }> {
    const { phoneNumber, otp, staleRefreshToken } = verifyOtpDto;

    await this.otpService.verifyOtp(phoneNumber, otp);

    let customer = await this.prisma.customer.findUnique({
      where: { phoneNumber },
    });

    if (!customer) {
      customer = await this.prisma.customer.create({
        data: { phoneNumber },
      });
    }

    const accessToken = await this.tokenService.generateAccessToken(customer, 'customer');
    const newRefreshToken = await this.tokenService.generateRefreshToken(customer.id, 'customer', staleRefreshToken);
    return { accessToken, refreshToken: newRefreshToken };
  }

  async logoutCustomer(refreshToken: string): Promise<{ success: boolean }> {
    if (!refreshToken || !refreshToken.includes('.')) {
      throw new UnauthorizedException('Invalid refresh token format');
    }

    const [sessionId] = refreshToken.split('.', 2);
    await this.prisma.customerSession.deleteMany({
      where: { id: sessionId },
    });

    return { success: true };
  }
}
