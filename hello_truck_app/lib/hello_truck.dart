import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_truck_app/models/auth_state.dart';
import 'package:hello_truck_app/providers/app_initializer_provider.dart.dart';
import 'package:hello_truck_app/providers/auth_providers.dart';
import 'package:hello_truck_app/providers/booking_providers.dart';
import 'package:hello_truck_app/providers/fcm_providers.dart';
import 'package:hello_truck_app/providers/provider_registry.dart';
import 'package:hello_truck_app/screens/home/home_screen.dart';
import 'package:hello_truck_app/screens/profile/profile_screen.dart';
import 'package:hello_truck_app/screens/bookings/bookings_screen.dart';
import 'package:hello_truck_app/screens/onboarding/onboarding_screen.dart';
import 'package:hello_truck_app/widgets/bottom_navbar.dart';
import 'package:hello_truck_app/widgets/snackbars.dart';

class HelloTruck extends ConsumerStatefulWidget {
  const HelloTruck({super.key});

  @override
  ConsumerState<HelloTruck> createState() => _HelloTruckState();
}

class _HelloTruckState extends ConsumerState<HelloTruck> {
  final List<Widget> _screens = List.filled(3, const SizedBox.shrink());
  final List<bool> _screenLoaded = List.filled(3, false); // Track loaded state
  bool _hasSetupListener = false;

  void _loadScreen(int index, int bookingsKey) {
    if (!_screenLoaded[index]) {
      _screens[index] = switch (index) {
        0 => const HomeScreen(),
        1 => BookingsScreen(key: ValueKey(bookingsKey)),
        2 => const ProfileScreen(),
        _ => const SizedBox.shrink(),
      };
      _screenLoaded[index] = true;
    } else if (index == 1) {
      // Always update BookingsScreen with new key to force rebuild
      _screens[1] = BookingsScreen(key: ValueKey(bookingsKey));
    }
  }

  void _setupListeners(AsyncValue<AuthState> authState) {
      if (!_hasSetupListener) {
        // Show offline snackbar if user is offline
        if (authState.value?.isOffline == true) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            SnackBars.error(context, 'You are offline. Please check your internet connection.');
          });
        }

        _hasSetupListener = true;
      }
      // Listen for offline status changes
      ref.listen(authStateProvider, (previous, next) {
        if (previous?.value?.isOffline == false && next.value?.isOffline == true) {
          SnackBars.error(context, 'You are offline. Please check your internet connection.');
        }
        else if (previous?.value?.isOffline == true && next.value?.isOffline == false) {
          SnackBars.success(context, 'You are back online');
        }
      });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final api = ref.watch(apiProvider);
    final authState = ref.watch(authStateProvider);
    final selectedIndex = ref.watch(selectedTabIndexProvider);
    final bookingsKey = ref.watch(bookingsScreenKeyProvider);

    _setupListeners(authState);

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

    // Run app initializer and watch it to keep it running
    ref.watch(appInitializerProvider);

    // Handle fcm events
    ref.watch(fcmEventsHandlerProvider);

    // Handle app lifecycle events
    ref.watch(appLifecycleHandlerProvider);

    _loadScreen(selectedIndex, bookingsKey);

    return Scaffold(
      body: IndexedStack(
        index: selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        selectedIndex: selectedIndex,
        onItemSelected: (index) {
          if (index == 1) {
            ref.invalidate(activeBookingsProvider);
          }
          ref.read(selectedTabIndexProvider.notifier).state = index;
        },
      ),
    );
  }
}
