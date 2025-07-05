import {
  WebSocketGateway,
  WebSocketServer,
  OnGatewayConnection,
  OnGatewayDisconnect,
  SubscribeMessage,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { AuthService } from './auth.service';
import { UnauthorizedException } from '@nestjs/common';

@WebSocketGateway({
  cors: {
    origin: '*',
  },
})
export class AuthGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  constructor(private authService: AuthService) {}

  async handleConnection(client: Socket) {
    try {
      const refreshToken = client.handshake.auth?.token as string;
      if (!refreshToken)
        throw new UnauthorizedException('Missing authorization header');
      const user = await this.authService.validateRefreshToken(refreshToken);
      if (!user) throw new UnauthorizedException("Invalid refresh token");

      client.data.user = user;
    } catch (err) {
      client.emit('unauthenticated');
      client.disconnect();
    }
  }

  handleDisconnect(client: Socket) {
    console.log(`Client disconnected: ${client.id}`);
  }

  @SubscribeMessage('refresh-token')
  async handleRefreshToken(client: Socket, payload: { refreshToken: string }) {
    try {
      const { accessToken, refreshToken } =
        await this.authService.refreshAccessToken(payload.refreshToken);

      client.emit('access-token', { accessToken, refreshToken });
    } catch (error) {
      client.emit('auth-error', { message: 'Invalid refresh token' });

      // Force logout if refresh token is invalid
      if (error instanceof UnauthorizedException) {
        client.emit('force-logout');
      }
    }
  }
}
