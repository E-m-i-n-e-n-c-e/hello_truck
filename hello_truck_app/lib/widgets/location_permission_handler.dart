import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hello_truck_app/services/location_service.dart';
import 'package:hello_truck_app/providers/location_providers.dart';

class LocationPermissionHandler extends ConsumerStatefulWidget {
  final Widget child;
  final VoidCallback? onPermissionGranted;
  final VoidCallback? onPermissionDenied;

  const LocationPermissionHandler({
    super.key,
    required this.child,
    this.onPermissionGranted,
    this.onPermissionDenied,
  });

  @override
  ConsumerState<LocationPermissionHandler> createState() => _LocationPermissionHandlerState();
}

class _LocationPermissionHandlerState extends ConsumerState<LocationPermissionHandler> {
  LocationPermissionStatus? _permissionStatus;
  bool _isCheckingPermission = true;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    final locationService = ref.read(locationServiceProvider);
    final status = await locationService.checkAndRequestPermissions();

    setState(() {
      _permissionStatus = status;
      _isCheckingPermission = false;
    });

    if (status == LocationPermissionStatus.granted) {
      widget.onPermissionGranted?.call();
    } else {
      widget.onPermissionDenied?.call();
    }
  }

  Future<void> _requestPermission() async {
    setState(() {
      _isCheckingPermission = true;
    });
    await _checkLocationPermission();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_isCheckingPermission) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            ),
            const SizedBox(height: 16),
            Text(
              'Checking location permissions...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      );
    }

    if (_permissionStatus == LocationPermissionStatus.granted) {
      return widget.child;
    }

    // Show permission request UI
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _permissionStatus == LocationPermissionStatus.disabled
                  ? Icons.location_disabled_rounded
                  : Icons.location_off_rounded,
              size: 64,
              color: colorScheme.error,
            ),
            const SizedBox(height: 24),
            Text(
              _getPermissionTitle(),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _getPermissionDescription(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (_permissionStatus != LocationPermissionStatus.deniedForever)
              ElevatedButton.icon(
                onPressed: _requestPermission,
                icon: const Icon(Icons.location_on_rounded),
                label: Text(_getButtonText()),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              ),
            if (_permissionStatus == LocationPermissionStatus.deniedForever) ...[
              ElevatedButton.icon(
                onPressed: () => _openAppSettings(),
                icon: const Icon(Icons.settings_rounded),
                label: const Text('Open Settings'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _requestPermission,
                child: const Text('Check Again'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getPermissionTitle() {
    switch (_permissionStatus) {
      case LocationPermissionStatus.disabled:
        return 'Location Services Disabled';
      case LocationPermissionStatus.denied:
        return 'Location Permission Required';
      case LocationPermissionStatus.deniedForever:
        return 'Location Permission Permanently Denied';
      default:
        return 'Location Access Required';
    }
  }

  String _getPermissionDescription() {
    switch (_permissionStatus) {
      case LocationPermissionStatus.disabled:
        return 'Please enable location services in your device settings to use this feature.';
      case LocationPermissionStatus.denied:
        return 'We need location access to show your current position and help you select your address accurately.';
      case LocationPermissionStatus.deniedForever:
        return 'Location permission has been permanently denied. Please enable it in app settings to continue.';
      default:
        return 'Location access is required for this feature to work properly.';
    }
  }

  String _getButtonText() {
    switch (_permissionStatus) {
      case LocationPermissionStatus.disabled:
        return 'Enable Location Services';
      case LocationPermissionStatus.denied:
        return 'Grant Permission';
      default:
        return 'Request Permission';
    }
  }

  void _openAppSettings() async {
    await Geolocator.openAppSettings();
  }
}
