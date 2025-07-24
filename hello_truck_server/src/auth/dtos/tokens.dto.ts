import { Expose } from "class-transformer";

export class TokenResponseDto {
  @Expose()
  accessToken: string;

  @Expose()
  refreshToken: string;
}

export class refreshTokenDto {
  @Expose()
  refreshToken: string;
}
