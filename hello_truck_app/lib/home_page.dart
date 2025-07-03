import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_truck_app/auth/auth_providers.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class HelloTruck extends ConsumerWidget {
  const HelloTruck({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hello Truck'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              // Show confirmation dialog
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('CANCEL'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('LOGOUT'),
                    ),
                  ],
                ),
              );
              
              // Logout if confirmed
              if (shouldLogout == true) {
                const storage = FlutterSecureStorage();
                await storage.deleteAll();
                
                final authSocket = ref.read(authSocketProvider);
                authSocket.emitUnauthenticated();
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/hello_truck.png',
              height: 150,
            ),
            const SizedBox(height: 24),
            const Text(
              'Welcome to Hello Truck!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'You are successfully logged in.',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
} 