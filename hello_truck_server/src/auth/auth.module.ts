import { Module } from '@nestjs/common';
import { AuthService } from './auth.service';
import { AuthController } from './auth.controller';
import { PrismaModule } from '../prisma/prisma.module';
import { AuthGateway } from './auth.gateway';
import { OtpModule } from '../otp/otp.module';
import { TokenModule } from '../token/token.module';

@Module({
  imports: [
    PrismaModule,
    OtpModule,
    TokenModule,
  ],
  controllers: [AuthController],
  providers: [AuthService, AuthGateway],
  exports: [AuthService],
})
export class AuthModule {}
