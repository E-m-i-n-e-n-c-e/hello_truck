import { Controller, Post, Body, HttpCode, HttpStatus } from '@nestjs/common';
import { seconds, Throttle } from '@nestjs/throttler';
import { AuthService } from './auth.service';
import { VerifyOtpDto } from './dtos/verify-otp.dto';
import { SendOtpDto } from './dtos/send-otp.dto';

@Throttle({ default: { ttl: seconds(60), limit: 5 } })
@Controller('auth/customer')
export class CustomerAuthController {
  constructor(private authService: AuthService) {}

  @Post('send-otp')
  @HttpCode(HttpStatus.OK)
  sendCustomerOtp(@Body() body: SendOtpDto) {
    return this.authService.sendOtp(body.phoneNumber);
  }

  @Post('verify-otp')
  @HttpCode(HttpStatus.OK)
  verifyCustomerOtp(@Body() body: VerifyOtpDto) {
    return this.authService.verifyCustomerOtp(body);
  }

  @Post('logout')
  @HttpCode(HttpStatus.OK)
  logoutCustomer(@Body() body: { refreshToken: string }) {
    return this.authService.logoutCustomer(body.refreshToken);
  }

  @Post('refresh-token')
  @HttpCode(HttpStatus.OK)
  refreshCustomerToken(@Body() body: { refreshToken: string }) {
    return this.authService.refreshToken(body.refreshToken, 'customer');
  }
}
