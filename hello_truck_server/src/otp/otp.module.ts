import { Module } from '@nestjs/common';
import { OtpService } from './otp.service';
import { ScheduleModule } from '@nestjs/schedule';
import { PrismaModule } from '../prisma/prisma.module';

@Module({
  imports: [ScheduleModule.forRoot(), PrismaModule],
  providers: [OtpService],
  exports: [OtpService]
})
export class OtpModule {}
