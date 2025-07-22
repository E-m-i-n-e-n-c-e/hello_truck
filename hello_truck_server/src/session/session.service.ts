import { Injectable, UnauthorizedException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { Customer, Driver, CustomerSession, DriverSession, Prisma } from '@prisma/client';
import * as crypto from 'crypto';

export type UserType = 'customer' | 'driver';
export type User = Customer | Driver;
export type Session = CustomerSession | DriverSession;
export type SessionWithUser = Session & { user: User };

@Injectable()
export class SessionService {
  constructor(private prisma: PrismaService) {}

  private generateToken(): string {
    return crypto.randomBytes(64).toString('hex');
  }

  private getExpiryDate(): Date {
    return new Date(Date.now() + 1000 * 60 * 60 * 24 * 30); // 30 days
  }

  async createSession(userId: string, userType: UserType): Promise<Session> {
    const token = this.generateToken();
    const expiresAt = this.getExpiryDate();

    if (userType === 'customer') {
      const session = await this.prisma.customerSession.create({
        data: {
          customerId: userId,
          token,
          expiresAt,
        },
      });
      return {
        ...session,
      };
    } else {
      const session = await this.prisma.driverSession.create({
        data: {
          driverId: userId,
          token,
          expiresAt,
        },
      });
      return session;
    }
  }

  async findSession(sessionId: string, userType: UserType): Promise<SessionWithUser | null> {
    if (userType === 'customer') {
      const session = await this.prisma.customerSession.findUnique({ where: { id: sessionId }, include: { customer: true } });
      if (!session) return null;
      return {
        ...session,
        user: session.customer,
      };
    } else {
      const session = await this.prisma.driverSession.findUnique({ where: { id: sessionId }, include: { driver: true } });
      if (!session) return null;
      return {
        ...session,
        user: session.driver,
      };
    }
  }

  async updateSession(sessionId: string, userType: UserType, data: Partial<Session>): Promise<void> {
    if (userType === 'customer') {
      await this.prisma.customerSession.updateMany({ where: { id: sessionId }, data });
    } else {
      await this.prisma.driverSession.updateMany({ where: { id: sessionId }, data });
    }
  }

  async deleteSession(sessionId: string, userType: UserType): Promise<void> {
    if (userType === 'customer') {
      await this.prisma.customerSession.deleteMany({
        where: { id: sessionId },
      });
    } else {
      await this.prisma.driverSession.deleteMany({
        where: { id: sessionId },
      });
    }
  }

  async deleteAllUserSessions(userId: string, userType: UserType): Promise<void> {
    if (userType === 'customer') {
      await this.prisma.customerSession.deleteMany({
        where: { customerId: userId },
      });
    } else {
      await this.prisma.driverSession.deleteMany({
        where: { driverId: userId },
      });
    }
  }
}