import 'package:jwt_decoder/jwt_decoder.dart';

class AuthState {
  final String userId;
  final String? phoneNumber;
  final bool isAuthenticated;
  final String? token;
  Function? signIn;
  Function? signOut;

  AuthState({
    required this.userId,
    this.phoneNumber,
    required this.isAuthenticated,
    this.token,
  });

  factory AuthState.fromToken(String? token) {
    if (token == null || token.isEmpty || JwtDecoder.isExpired(token)) {
      return AuthState.unauthenticated();
    }

    try {
      final payload = JwtDecoder.decode(token);
      return AuthState(
        userId: payload['id'],
        isAuthenticated: true,
        token: token,
      );
    } catch (_) {
      return AuthState.unauthenticated();
    }
  }

  factory AuthState.unauthenticated() {
    return AuthState(userId: '', isAuthenticated: false);
  }
}
