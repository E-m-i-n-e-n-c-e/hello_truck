import { Controller, Post, Body, HttpCode, HttpStatus } from '@nestjs/common';
import { seconds, Throttle } from '@nestjs/throttler';
import { AuthService } from './auth.service';
import { VerifyOtpDto } from './dtos/verify-otp.dto';
import { SendOtpDto } from './dtos/send-otp.dto';

@Throttle({ default: { ttl: seconds(60), limit: 5 } })
@Controller('auth/driver')
export class DriverAuthController {
  constructor(private authService: AuthService) {}

  @Post('send-otp')
  @HttpCode(HttpStatus.OK)
  sendDriverOtp(@Body() body: SendOtpDto) {
    return this.authService.sendOtp(body.phoneNumber);
  }

  @Post('verify-otp')
  @HttpCode(HttpStatus.OK)
  verifyDriverOtp(@Body() body: VerifyOtpDto) {
    return this.authService.verifyDriverOtp(body);
  }

  @Post('logout')
  @HttpCode(HttpStatus.OK)
  logoutDriver(@Body() body: { refreshToken: string }) {
    return this.authService.logoutDriver(body.refreshToken);
  }

  @Throttle({ default: { ttl: seconds(60), limit: 10 } })
  @Post('refresh-token')
  @HttpCode(HttpStatus.OK)
  refreshDriverToken(@Body() body: { refreshToken: string }) {
    return this.authService.refreshToken(body.refreshToken, 'driver');
  }
}
