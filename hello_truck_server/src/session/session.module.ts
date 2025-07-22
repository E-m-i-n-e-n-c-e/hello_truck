import { Module } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { JwtModule, JwtService } from '@nestjs/jwt';
import { SessionService } from './session.service';
import { PrismaModule } from 'src/prisma/prisma.module';

@Module({
  imports: [PrismaModule, JwtModule],
  providers: [SessionService],
  exports: [SessionService],
})
export class SessionModule {}
