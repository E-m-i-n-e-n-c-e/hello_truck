import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_truck_app/models/auth_state.dart';
import 'package:hello_truck_app/providers/auth_providers.dart';
import 'package:hello_truck_app/providers/location_providers.dart';
import 'package:hello_truck_app/screens/home_screen.dart';
import 'package:hello_truck_app/screens/profile/profile_screen.dart';
import 'package:hello_truck_app/screens/map_screen.dart';
import 'package:hello_truck_app/screens/onboarding/onboarding_screen.dart';
import 'package:hello_truck_app/widgets/bottom_navbar.dart';
import 'package:hello_truck_app/widgets/snackbars.dart';

class HelloTruck extends ConsumerStatefulWidget {
  const HelloTruck({super.key});

  @override
  ConsumerState<HelloTruck> createState() => _HelloTruckState();
}

class _HelloTruckState extends ConsumerState<HelloTruck> {
  int _selectedIndex = 0;
  final List<Widget> _screens = List.filled(3, const SizedBox.shrink());
  final List<bool> _screenLoaded = List.filled(3, false); // Track loaded state
  bool _hasSetupListener = false;

  void _loadScreen(int index) {
    if (!_screenLoaded[index]) {
      _screens[index] = switch (index) {
        0 => const HomeScreen(),
        1 => const MapScreen(),
        2 => const ProfileScreen(),
        _ => const SizedBox.shrink(),
      };
      _screenLoaded[index] = true;
    }
  }

  void _setupListeners(AsyncValue<AuthState> authState) {
      if (!_hasSetupListener) {
        // Preload providers
        ref.read(currentPositionStreamProvider);
        ref.read(customerProvider);
        ref.read(gstDetailsProvider);

        // Show offline snackbar if user is offline
        if (authState.value?.isOffline == true) {
          SnackBars.error(context, 'You are offline. Please check your internet connection.');
        }

        _hasSetupListener = true;
      }
      // Listen for offline status changes
      ref.listen(authStateProvider, (previous, next) {
        if (next.value?.isOffline == true) {
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

    _loadScreen(_selectedIndex);

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        selectedIndex: _selectedIndex,
        onItemSelected: (index) {
          if (index == 2) {
            ref.invalidate(customerProvider);
            ref.invalidate(gstDetailsProvider);
          }
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}
