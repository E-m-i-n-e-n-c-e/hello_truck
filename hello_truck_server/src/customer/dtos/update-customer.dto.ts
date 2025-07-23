import { IsString, IsEmail, IsOptional, IsBoolean } from 'class-validator';

export class UpdateCustomerDto {
  @IsString()
  @IsOptional()
  firstName?: string;

  @IsString()
  @IsOptional()
  lastName?: string;

  @IsEmail()
  @IsOptional()
  email?: string;

  @IsBoolean()
  @IsOptional()
  isBusiness?: boolean;

  @IsString()
  @IsOptional()
  referralCode?: string;
}