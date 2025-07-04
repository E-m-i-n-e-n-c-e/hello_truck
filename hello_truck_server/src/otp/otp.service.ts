import { Injectable, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { Cron } from '@nestjs/schedule';
import * as bcrypt from 'bcrypt';

// Run npm install bcrypt and npm install @types/bcrypt --save-dev

@Injectable()
export class OtpService {
  constructor(
    private prisma: PrismaService,
  ) {}

  // Send OTP
  async sendOtp(phoneNumber: string): Promise<{ success: boolean; message: string }> {
    // Generate OTP
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const hashedOtp = await bcrypt.hash(otp, 10);
    const expiresAt = new Date(Date.now() + 30 * 1000); // OTP valid for 30 seconds

    // Store OTP in database
    await this.prisma.otpVerification.create({
      data: {
        phoneNumber,
        otp:hashedOtp,
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

  // Verify OTP
  async verifyOtp(phoneNumber: string, otp: string): Promise<boolean> {
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

    if (!otpVerification) {
      throw new BadRequestException('Invalid or expired OTP');
    }

    const isValidOtp = await bcrypt.compare(otp, otpVerification.otp);
    if (!isValidOtp) {
      await this.prisma.otpVerification.update({
      where: { id: otpVerification.id },
      data: { retryCount: { increment: 1 } },
      });
      throw new BadRequestException('Invalid OTP');
    }

    if( otpVerification.retryCount > 5) {
      throw new BadRequestException('Too many attempts, please request a new OTP');
    }

    // Mark OTP as verified
    await this.prisma.otpVerification.update({
      where: { id: otpVerification.id },
      data: { verified: true },
    });

    return true;
  }
}
