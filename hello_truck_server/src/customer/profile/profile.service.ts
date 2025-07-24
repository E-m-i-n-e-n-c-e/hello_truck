import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from 'src/prisma/prisma.service';
import { UpdateProfileDto, CreateProfileDto } from '../dtos/profile.dto';
import { GstService } from '../gst/gst.service';
@Injectable()
export class ProfileService {
  constructor(private prisma: PrismaService, private gstService: GstService) {}

  async getProfile(userId: string) {
    const customer = await this.prisma.customer.findUnique({
      where: { id: userId },
      select: {
        firstName: true,
        lastName: true,
        email: true,
        phoneNumber: true,
        referralCode: true,
        isBusiness: true,
      }
    });

    if (!customer) {
      throw new NotFoundException('Customer not found');
    }

    return customer;
  }

  async updateProfile(userId: string, updateProfileDto: UpdateProfileDto) {
    await this.prisma.customer.update({
      where: { id: userId },
      data: updateProfileDto
    });

    return {success:true, message:'Profile updated successfully'};
  }

  async createProfile(userId: string, createProfileDto: CreateProfileDto) {
    const customer = await this.prisma.customer.findUnique({
      where: { id: userId },
    });

    if (!customer) {
      throw new NotFoundException('Customer not found');
    }

    if(customer.firstName) {
      throw new BadRequestException('Profile already exists');
    }

    const { gstDetails, ...profileData } = createProfileDto;

    await this.prisma.customer.update({
      where: { id: userId },
      data: {
        ...profileData,
        isBusiness: gstDetails ? true : false
      }
    });

    if(gstDetails) {
      await this.gstService.addGstDetails(userId, gstDetails);
    }

    return {success:true, message:'Profile created successfully'};
  }
}
