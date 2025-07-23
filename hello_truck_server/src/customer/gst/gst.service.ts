import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from 'src/prisma/prisma.service';
import { CreateGstDetailsDto, UpdateGstDetailsDto } from '../dtos/gst-details.dto';
import { CustomerGstDetails } from '@prisma/client';

@Injectable()
export class GstService {
  constructor(private prisma: PrismaService) {}

  async addGstDetails(userId: string, createGstDetailsDto: CreateGstDetailsDto) {
    const existingGst = await this.prisma.customerGstDetails.findUnique({
      where: { gstNumber: createGstDetailsDto.gstNumber }
    });

    if (existingGst) {
      throw new BadRequestException('GST number already exists');
    }
    await this.prisma.$transaction(async (tx) => {
      await tx.customerGstDetails.create({
        data: {
          ...createGstDetailsDto,
        customer: {
            connect: { id: userId }
          }
        },
      });
      await tx.customer.update({
        where: { id: userId },
        data: { isBusiness: true }
      });
    });

    return {success:true, message:'GST details added successfully'};
  }

  async getGstDetails(userId: string): Promise<CustomerGstDetails[]> {
    const gstDetails = await this.prisma.customerGstDetails.findMany({
      where: { customerId: userId, isActive: true },
      orderBy: { createdAt: 'desc' },
    });

    return gstDetails;
  }

  async getGstDetailsById(userId: string, id: string): Promise<CustomerGstDetails> {
    const gstDetails = await this.prisma.customerGstDetails.findUnique({
      where: { id, customerId: userId, isActive: true },
    });

    if (!gstDetails) {
      throw new NotFoundException('GST details not found');
    }

    return gstDetails;
  }

  async updateGstDetails(userId: string, id: string, updateGstDetailsDto: UpdateGstDetailsDto) {
    const gstDetails = await this.prisma.customerGstDetails.updateMany({
      where: { id, customerId: userId, isActive: true },
      data: updateGstDetailsDto,
    });

    if(gstDetails.count === 0) {
      throw new NotFoundException('GST details not found');
    }

    return {success:true, message:'GST details updated successfully'};
  }

  async deactivateGstDetails(userId: string, id: string) {
    const gstDetails = await this.prisma.customerGstDetails.updateMany({
      where: { id, customerId: userId, isActive: true },
      data: { isActive: false }
    });

    if(gstDetails.count === 0) {
      throw new NotFoundException('GST details not found');
    }

    return {success:true, message:'GST details deactivated successfully'};
  }
}