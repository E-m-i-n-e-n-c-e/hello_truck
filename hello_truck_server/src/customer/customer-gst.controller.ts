import { Controller, Get, Post, Body, UseGuards, Param, Put } from '@nestjs/common';
import { User } from 'src/token/decorators/user.decorator';
import { CreateGstDetailsDto, DeactivateGstDetailsDto, UpdateGstDetailsDto } from './dtos/gst-details.dto';
import { GstService } from './gst/gst.service';
import { RolesGuard } from 'src/token/guards/roles.guard';
import { seconds } from '@nestjs/throttler';
import { Throttle } from '@nestjs/throttler';
import { AccessTokenGuard } from 'src/token/guards/access-token.guard';
import { Roles } from 'src/token/decorators/roles.decorator';

@Controller('customer/gst')
@UseGuards(AccessTokenGuard, RolesGuard)
@Roles('customer')
@Throttle({ default: { ttl: seconds(60), limit: 40 } })
export class CustomerGstController {
  constructor(private readonly gstService: GstService) {}

  @Post()
  async addGstDetails(
    @User('userId') userId: string,
    @Body() createGstDetailsDto: CreateGstDetailsDto,
  ) {
    return this.gstService.addGstDetails(userId, createGstDetailsDto);
  }

  @Get()
  async getGstDetails(@User('userId') userId: string) {
    return this.gstService.getGstDetails(userId);
  }

  @Get(':id')
  async getGstDetailsById(
    @User('userId') userId: string,
    @Param('id') id: string,
  ) {
    return this.gstService.getGstDetailsById(userId, id);
  }

  @Put(':id')
  async updateGstDetails(
    @User('userId') userId: string,
    @Param('id') id: string,
    @Body() updateGstDetailsDto: UpdateGstDetailsDto,
  ) {
    return this.gstService.updateGstDetails(userId, id, updateGstDetailsDto);
  }

  @Post('deactivate')
  async deactivateGstDetails(
    @User('userId') userId: string,
    @Body() deactivateGstDetailsDto: DeactivateGstDetailsDto,
  ) {
    return this.gstService.deactivateGstDetails(userId, deactivateGstDetailsDto.id);
  }
}
