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

    final teal = HSLColor.fromAHSL(1.0, 180, 1.0, 0.25).toColor(); // 0, 128, 128 teal
    final lightTeal = HSLColor.fromAHSL(1.0, 180, 1.0, 0.30).toColor(); // 0, 153, 153 light teal
    const offWhite = Color.fromRGBO(253, 253, 253, 1);
    const dimWhite = Color.fromRGBO(248, 248, 248, 1);
    const brightWhite = Color.fromRGBO(254, 254, 254, 1);

    // Professional color scheme based on the teal logo
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: lightTeal,
      onPrimary: brightWhite,
      secondary: teal,
      onSecondary: brightWhite,
      error: const Color(0xFFE53935),
      onError: brightWhite,
      surface: offWhite,
      surfaceDim: dimWhite,
      surfaceBright: brightWhite,
      onSurface: const Color(0xFF212121),
    );

    final authState = ref.watch(authStateProvider);
    final api = ref.watch(apiProvider);
    final isLoading = authState.isLoading || api.isLoading;
    final isAnimationComplete = ref.watch(AnimatedSplashScreenState.isAnimationComplete);

    if (isLoading || !isAnimationComplete) {
      return AnimatedSplashScreen(
        backgroundColor: MediaQuery.of(context).platformBrightness == Brightness.dark ? teal : lightTeal,
      );
    }

    return MaterialApp(
      title: 'Hello Truck',
      theme: ThemeData(
        colorScheme: colorScheme,
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
        dialogTheme: DialogThemeData(
          backgroundColor: colorScheme.surfaceDim,
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
