import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from 'src/prisma/prisma.service';
import { UpdateProfileDto } from '../dtos/profile.dto';
import { Driver } from '@prisma/client';

@Injectable()
export class ProfileService {
  constructor(private readonly prisma: PrismaService) {}

  async getProfile(userId: string): Promise<Driver> {
    const driver = await this.prisma.driver.findUnique({
      where: { id: userId },
    });

    if (!driver) {
      throw new NotFoundException('Driver not found');
    }

    return driver;
  }

  async updateProfile(userId: string, updateProfileDto: UpdateProfileDto) {
    await this.prisma.driver.update({
      where: { id: userId },
      data: updateProfileDto,
    });

    return {success:true, message:'Profile updated successfully'};
  }
}