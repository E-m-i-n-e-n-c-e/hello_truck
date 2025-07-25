import { $Enums, Driver } from "@prisma/client";
import { Expose } from "class-transformer";
import { IsEmail, IsOptional, IsPhoneNumber, IsString } from "class-validator";

export class UpdateProfileDto implements Partial<Driver> {
  @IsString()
  @IsOptional()
  firstName?: string;

  @IsString()
  @IsOptional()
  lastName?: string;

  @IsEmail()
  @IsOptional()
  email?: string;

  @IsString()
  @IsOptional()
  @IsPhoneNumber('IN')
  alternatePhone?: string;

  @IsString()
  @IsOptional()
  photo?: string;
}

export class ProfileResponseDto implements Driver {
  id: string;
  isActive: boolean;

  @Expose()
  phoneNumber: string;
  @Expose()
  firstName: string | null;
  @Expose()
  lastName: string | null;
  @Expose()
  email: string | null;
  @Expose()
  alternatePhone: string | null;
  @Expose()
  referalCode: string | null;
  @Expose()
  photo: string | null;
  @Expose()
  verificationStatus: $Enums.VerificationStatus;
  @Expose()
  createdAt: Date;
  @Expose()
  updatedAt: Date;
}

