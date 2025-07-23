import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from 'src/prisma/prisma.service';
import { UpdateCustomerDto } from '../dtos/update-customer.dto';

@Injectable()
export class ProfileService {
  constructor(private prisma: PrismaService) {}

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

  async updateProfile(userId: string, updateCustomerDto: UpdateCustomerDto) {
    await this.prisma.customer.update({
      where: { id: userId },
      data: updateCustomerDto
    });

    return {success:true, message:'Profile updated successfully'};
  }
}
