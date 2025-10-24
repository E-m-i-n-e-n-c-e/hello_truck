import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_truck_app/providers/auth_providers.dart';
import 'package:hello_truck_app/hello_truck.dart';
import 'package:hello_truck_app/login_page.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:hello_truck_app/services/fcm_service.dart';
import 'package:hello_truck_app/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  // Preserve splash screen until app is fully loaded
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Lock orientation to portrait up or down
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Remove splash screen once the app is built
    FlutterNativeSplash.remove();

    // Professional color scheme based on the teal logo
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: const Color(0xFF22AAAE), // Teal from logo
      onPrimary: Colors.white,
      secondary: const Color(0xFF007f82), // Darker teal for accents
      onSecondary: Colors.white,
      error: const Color(0xFFE53935),
      onError: Colors.white,
      surface: Colors.white,
      onSurface: const Color(0xFF212121),
    );

    final authState = ref.watch(authStateProvider);
    final api = ref.watch(apiProvider);
    final isLoading = authState.isLoading || api.isLoading;
    final isAnimationComplete = ref.watch(AnimatedSplashScreenState.isAnimationComplete);

    if (isLoading || !isAnimationComplete) {
      return AnimatedSplashScreen(
        backgroundColor: MediaQuery.of(context).platformBrightness == Brightness.dark
            ? const Color(0xFF007F82)
            : const Color(0xFF22AAAE),
      );
    }

    return MaterialApp(
      title: 'Hello Truck',
      theme: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colorScheme.primary),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colorScheme.primary.withValues(alpha: 0.5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colorScheme.primary, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
      themeMode: ThemeMode.light,
      home: authState.when(
        data: (authState) =>
            authState.isAuthenticated ? const HelloTruck() : const LoginPage(),
        error: (error, stackTrace) => Scaffold(
          body: Center(child: Text('Error: ${error.toString()}')),
        ),
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }
}
