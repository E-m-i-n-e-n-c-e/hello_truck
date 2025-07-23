import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:equatable/equatable.dart';

class AuthState extends Equatable {
  final String userId;
  final bool isAuthenticated;
  final String token;
  final bool isOffline;
  final bool hasCompletedOnboarding;

  const AuthState({
    required this.userId,
    required this.isAuthenticated,
    required this.token,
    this.isOffline = false,
    this.hasCompletedOnboarding=false,
  });

  @override
  List<Object> get props => [
    userId,
    isAuthenticated,
    token,
    isOffline,
    hasCompletedOnboarding,
  ];

  factory AuthState.fromToken(String? token, {bool isOffline = false}) {
    if (token == null || token.isEmpty) {
      return AuthState.unauthenticated();
    }

    try {
      final payload = JwtDecoder.decode(token);
      return AuthState(
        userId: payload['userId'],
        isAuthenticated: true,
        token: token,
        isOffline: isOffline,
        hasCompletedOnboarding: payload['hasCompletedOnboarding'],
      );
    } catch (_) {
      return AuthState.unauthenticated();
    }
  }

  factory AuthState.unauthenticated() {
    return AuthState(
      userId: '',
      isAuthenticated: false,
      token: '',
    );
  }
}
