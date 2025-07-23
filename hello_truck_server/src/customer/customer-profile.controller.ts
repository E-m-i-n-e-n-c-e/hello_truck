import { Controller, Get, Put, Post, Body, UseGuards } from '@nestjs/common';
import { UpdateCustomerDto } from './dtos/update-customer.dto';
import { AccessTokenGuard } from '../token/guards/access-token.guard';
import { User } from '../token/decorators/user.decorator';
import { Roles } from 'src/token/decorators/roles.decorator';
import { RolesGuard } from 'src/token/guards/roles.guard';
import { seconds, Throttle } from '@nestjs/throttler';
import { ProfileService } from './profile/profile.service';

@Controller('customer/profile')
@UseGuards(AccessTokenGuard, RolesGuard)
@Roles('customer')
@Throttle({ default: { ttl: seconds(60), limit: 40 } })
export class CustomerProfileController {
  constructor(private readonly profileService: ProfileService) {}

  @Get()
  async getProfile(@User('userId') userId: string) {
    return this.profileService.getProfile(userId);
  }

  @Put()
  async updateProfile(
    @User('userId') userId: string,
    @Body() updateCustomerDto: UpdateCustomerDto,
  ) {
    return this.profileService.updateProfile(userId, updateCustomerDto);
  }
}
