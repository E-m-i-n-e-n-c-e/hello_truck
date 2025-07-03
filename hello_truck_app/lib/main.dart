import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_truck_app/auth/auth_providers.dart';
import 'package:hello_truck_app/home_page.dart';
import 'package:hello_truck_app/login_page.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme =
        ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 255, 145, 77));

    return MaterialApp(
      title: 'Hello Truck',
      theme: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
      ),
      home: ref.watch(authStateProvider).when(
        data: (authState) => authState.isAuthenticated ? const HelloTruck() : const LoginPage(),
        error: (error, stackTrace) => Scaffold(
          body: Center(
            child: Text('Error: ${error.toString()}'),
          ),
        ),
        loading: () => const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );
  }
}