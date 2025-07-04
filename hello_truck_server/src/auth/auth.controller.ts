import { Controller, Post, Body, HttpCode, HttpStatus } from '@nestjs/common';
import { seconds, Throttle } from '@nestjs/throttler';
import { AuthService } from './auth.service';
import { VerifyOtpDto } from './dtos/verify-otp.dto';
import { SendOtpDto } from './dtos/send-otp.dto';

@Controller('auth')
export class AuthController {
  constructor(private authService: AuthService) {}

  @Throttle({ default: { ttl: seconds(60), limit: 3 } })
  @Post('send-otp')
  @HttpCode(HttpStatus.OK)
  sendOtp(@Body() body: SendOtpDto) {
    return this.authService.sendOtp(body.phoneNumber);
  }

  @Throttle({ default: { ttl: seconds(60), limit: 3 } })
  @Post('verify-otp')
  @HttpCode(HttpStatus.OK)
  verifyOtp(@Body() body: VerifyOtpDto) {
    return this.authService.verifyOtp(body);
  }

  @Post('logout')
  @HttpCode(HttpStatus.OK)
  logout(@Body() body: { refreshToken: string }) {
    return this.authService.logout(body.refreshToken);
  }
}
