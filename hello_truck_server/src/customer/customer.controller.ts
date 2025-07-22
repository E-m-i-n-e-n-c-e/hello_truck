import { Controller, Get, Put, Body, UseGuards } from '@nestjs/common';
import { CustomerService } from './customer.service';
import { UpdateCustomerDto } from './dtos/update-profile.dto';
import { AccessTokenGuard } from '../token/guards/access-token.guard';
import { User } from '../token/decorators/user.decorator';

@Controller('customer')
@UseGuards(AccessTokenGuard)
export class CustomerController {
  constructor(private readonly customerService: CustomerService) {}

  @Get('profile')
  async getProfile(@User('userId') userId: string) {
    return this.customerService.getProfile(userId);
  }

  @Put('profile')
  async updateProfile(
    @User('userId') userId: string,
    @Body() updateCustomerDto: UpdateCustomerDto,
  ) {
    return this.customerService.updateProfile(userId, updateCustomerDto);
  }
}
