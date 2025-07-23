import { IsString, IsNotEmpty, Matches, IsOptional } from 'class-validator';

export class CreateGstDetailsDto {
  @IsNotEmpty()
  @IsString()
  @Matches(/^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$/, {
    message: 'Invalid GST number format',
  })
  gstNumber: string;

  @IsNotEmpty()
  @IsString()
  businessName: string;

  @IsNotEmpty()
  @IsString()
  businessAddress: string;
}

export class UpdateGstDetailsDto {
  @IsOptional()
  @IsString()
  @Matches(/^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$/, {
    message: 'Invalid GST number format',
  })
  gstNumber?: string;

  @IsOptional()
  @IsString()
  businessName?: string;

  @IsOptional()
  @IsString()
  businessAddress?: string;
}

export class DeactivateGstDetailsDto {
  @IsNotEmpty()
  @IsString()
  id: string;
}