import { Injectable, UnauthorizedException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { JwtService } from '@nestjs/jwt';
import * as crypto from 'crypto';
import { User } from '@prisma/client';

@Injectable()
export class TokenService {
  constructor(private prisma: PrismaService, private jwtService: JwtService) {}

  async generateAccessToken(user: User): Promise<string> {
    const accessToken = await this.jwtService.signAsync({
      userId: user.id,
      userName: user.userName,
      phoneNumber: user.phoneNumber,
    });

    return accessToken;
  }

  async generateRefreshToken(userId: string, staleRefreshToken?: string): Promise<string> {
    const newToken = crypto.randomBytes(64).toString('hex');
    const expiresAt = new Date(Date.now() + 1000 * 60 * 60 * 24 * 30); // 30 days
  
    // If a stale refresh token is provided, delete the session
    if (staleRefreshToken) {
      await this.prisma.session.deleteMany({
        where: { id: staleRefreshToken.split('.', 2)[0] },
      });
    }
    
    // Create a new session
    const session = await this.prisma.session.create({
      data: {
        userId,
        token: newToken,
        expiresAt,
      },
    });
  
    return `${session.id}.${newToken}`;
  }

  async refreshAccessToken(refreshToken: string): Promise<{ accessToken: string; refreshToken: string }> {
    if (!refreshToken || !refreshToken.includes('.')) {
      throw new UnauthorizedException('Invalid refresh token format');
    }

    const [sessionId, tokenValue] = refreshToken.split('.', 2);

    const session = await this.prisma.session.findUnique({
      where: { id: sessionId },
      include: { user: true },
    });

    if (!session || session.expiresAt < new Date()) {
      throw new UnauthorizedException('Invalid or expired refresh token');
    }

    const isCurrentToken = session.token === tokenValue;
    const isOldToken = session.oldToken === tokenValue;
    
    if (!isCurrentToken && !isOldToken) {
      await this.prisma.session.deleteMany({ where: { id: session.id } });
      throw new UnauthorizedException('Invalid refresh token - session terminated');
    }

    const newToken = crypto.randomBytes(64).toString('hex');

    await this.prisma.session.update({
      where: { id: session.id },
      data: {
        token: newToken,
        ...(isCurrentToken && { oldToken: session.token }), // Only set oldToken if current token was used
        expiresAt: new Date(Date.now() + 1000 * 60 * 60 * 24 * 30), // Extend 30 days
      },
    });

    const accessToken = await this.generateAccessToken(session.user);

    return {
      accessToken,
      refreshToken: `${session.id}.${newToken}`,
    };
  }

  async validateAccessToken(token: string): Promise<User> {  
    try {
      const payload = this.jwtService.verify(token);
      const user = await this.prisma.user.findUnique({ where: { id: payload.userId } });
      if (!user) {
        throw new UnauthorizedException('Invalid token');
      }
      return user;
    } catch (error) {
      throw new UnauthorizedException('Invalid token');
    }
  }

  async validateRefreshToken(refreshToken: string): Promise<User> {
    if (!refreshToken || !refreshToken.includes('.')) {
      throw new UnauthorizedException('Invalid refresh token format');
    }

    const [sessionId, tokenValue] = refreshToken.split('.', 2);
    
    const session = await this.prisma.session.findUnique({
      where: { id: sessionId },
      include: { user: true },
    });

    if (!session || session.expiresAt < new Date()) {
      throw new UnauthorizedException('Invalid or expired refresh token');
    }

    // Check if token matches either current or old token
    if (session.token !== tokenValue && session.oldToken !== tokenValue) {
      // Security breach - delete the session
      await this.prisma.session.deleteMany({
        where: { id: sessionId },
      });
      throw new UnauthorizedException('Invalid refresh token - session terminated');
    }

    return session.user;
  }
}
