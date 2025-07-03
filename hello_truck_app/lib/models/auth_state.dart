import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:equatable/equatable.dart';

class AuthState extends Equatable {
  final String userId;
  final String phoneNumber;
  final bool isAuthenticated;
  final String token;

  const AuthState({
    required this.userId,
    required this.phoneNumber,
    required this.isAuthenticated,
    required this.token,
  });

  @override
  List<Object> get props => [userId, phoneNumber, isAuthenticated, token];

  factory AuthState.fromToken(String? token) {
    if (token == null || token.isEmpty || JwtDecoder.isExpired(token)) {
      return AuthState.unauthenticated();
    }

    try {
      final payload = JwtDecoder.decode(token);
      return AuthState(
        userId: payload['id'],
        phoneNumber: payload['phoneNumber'],
        isAuthenticated: true,
        token: token,
      );
    } catch (_) {
      return AuthState.unauthenticated();
    }
  }

  factory AuthState.unauthenticated() {
    return AuthState(
      userId: '',
      phoneNumber: '',
      isAuthenticated: false,
      token: '',
    );
  }
}
