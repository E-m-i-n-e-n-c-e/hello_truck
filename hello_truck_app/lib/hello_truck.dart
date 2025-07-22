import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_truck_app/providers/auth_providers.dart';
import 'package:hello_truck_app/screens/home_screen.dart';
import 'package:hello_truck_app/screens/profile_screen.dart';
import 'package:hello_truck_app/screens/map_screen.dart';
import 'package:hello_truck_app/screens/onboarding_screen.dart';
import 'package:hello_truck_app/widgets/bottom_navbar.dart';
import 'package:hello_truck_app/widgets/snackbars.dart';

// Navigation state provider
final navigationIndexProvider = StateProvider<int>((ref) => 0); // Start with Home selected
final screens=[
  const HomeScreen(),
  const MapScreen(),
  const ProfileScreen(),
];

class HelloTruck extends ConsumerWidget {
  const HelloTruck({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final api = ref.watch(apiProvider);
    final authState = ref.watch(authStateProvider);
    final selectedIndex = ref.watch(navigationIndexProvider);

    ref.listen(authStateProvider, (previous, next) {
      if (next.value?.isOffline == true) {
        SnackBars.error(context, 'You are offline. Please check your internet connection.');
      }
      else if (previous?.value?.isOffline == true && next.value?.isOffline == false) {
        SnackBars.success(context, 'You are back online');
      }
    });

    if (authState.isLoading || api.isLoading) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: Center(
          child: CircularProgressIndicator(color: colorScheme.secondary),
        ),
      );
    }

    if (authState.value?.hasCompletedOnboarding!=true) {
      return const OnboardingScreen();
    }

    return Scaffold(
      body: screens[selectedIndex],
      bottomNavigationBar: CustomBottomNavigationBar(
        selectedIndex: selectedIndex,
        onItemSelected: (index) => ref.read(navigationIndexProvider.notifier).state = index,
      ),
    );
  }
}
