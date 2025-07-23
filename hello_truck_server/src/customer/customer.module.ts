import { Module } from '@nestjs/common';
import { GstModule } from './gst/gst.module';
import { ProfileModule } from './profile/profile.module';
import { CustomerProfileController } from './customer-profile.controller';
import { CustomerGstController } from './customer-gst.controller';
import { TokenModule } from 'src/token/token.module';

@Module({
  imports: [GstModule, ProfileModule, TokenModule],
  controllers: [CustomerProfileController, CustomerGstController],
})
export class CustomerModule {}
