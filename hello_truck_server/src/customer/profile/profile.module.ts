import { Module } from '@nestjs/common';
import { ProfileService } from './profile.service';
import { PrismaModule } from 'src/prisma/prisma.module';
import { GstModule } from '../gst/gst.module';

@Module({
  imports: [PrismaModule, GstModule],
  providers: [ProfileService],
  exports: [ProfileService]
})
export class ProfileModule {}
