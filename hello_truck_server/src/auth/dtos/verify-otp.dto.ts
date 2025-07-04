import { IsNotEmpty, IsOptional, IsPhoneNumber, IsString } from 'class-validator';

export class VerifyOtpDto {
  @IsString()
  @IsNotEmpty()
  phoneNumber: string;
  @IsString()
  @IsNotEmpty()
  otp: string;

  @IsOptional()
  @IsString()
  staleRefreshToken?: string;
}