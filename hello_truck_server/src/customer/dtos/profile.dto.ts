import { IsString, IsEmail, IsOptional, ValidateNested } from 'class-validator';
import { Expose, Type } from 'class-transformer';
import { CreateGstDetailsDto } from './gst-details.dto';
import { Customer } from '@prisma/client';

export class CreateProfileDto implements Partial<Customer> {
  @IsString()
  firstName: string;

  @IsString()
  @IsOptional()
  lastName?: string;

  @IsEmail()
  @IsOptional()
  email?: string;

  @IsString()
  @IsOptional()
  referralCode?: string;

  @IsOptional()
  @ValidateNested()
  @Type(() => CreateGstDetailsDto)
  gstDetails?: CreateGstDetailsDto;
}

export class UpdateProfileDto implements Partial<Customer> {
  @IsString()
  @IsOptional()
  firstName?: string;

  @IsString()
  @IsOptional()
  lastName?: string;

  @IsEmail()
  @IsOptional()
  email?: string;
}

export class GetProfileResponseDto implements Partial<Customer> {
  @Expose()
  firstName: string | null;
  @Expose()
  lastName: string | null;
  @Expose()
  email: string | null;
  @Expose()
  isBusiness: boolean;
  @Expose()
  referralCode: string | null;
  @Expose()
  phoneNumber: string;
  @Expose()
  createdAt: Date;
  @Expose()
  updatedAt: Date;
  // Exclude id, isActive
}