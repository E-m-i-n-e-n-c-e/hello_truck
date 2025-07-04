import { Injectable } from '@nestjs/common';
import { Cron } from '@nestjs/schedule';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class CronService {
  constructor(private prisma: PrismaService) {}

  // Cleanup expired OTPs every minute
  @Cron('* * * * *')
  async cleanupExpiredOtps() {
    const result = await this.prisma.otpVerification.deleteMany({
      where: {
        expiresAt: {
          lt: new Date(),
        },
      },
    });
    console.log(`Cleaned up ${result.count} expired OTPs`);
  }

  // Cleanup expired sessions every day at midnight
  @Cron('0 0 * * *')
  async cleanupExpiredSessions() {
    const result = await this.prisma.session.deleteMany({
      where: {
        expiresAt: {
          lt: new Date(),
        },
      },
    });
    console.log(`Cleaned up ${result.count} expired sessions`);
  }
}
