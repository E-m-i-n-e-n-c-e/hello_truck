import 'dart:math';
import 'package:hello_truck_app/models/package.dart';

enum VehicleType {
  bike,
  van,
  pickup,
  truck,
}

class VehicleSpec {
  final VehicleType type;
  final String name;
  final String description;
  final double weightCapacity; // kg
  final double volumeCapacity; // cubic meters
  final double kmpl; // kilometers per liter
  final double ratePerKm; // base rate per kilometer
  final double ratePerKg; // alternative rate per kg
  final double loadingRate; // cost for loading service
  final String icon;
  final List<int> gradientColors;

  const VehicleSpec({
    required this.type,
    required this.name,
    required this.description,
    required this.weightCapacity,
    required this.volumeCapacity,
    required this.kmpl,
    required this.ratePerKm,
    required this.ratePerKg,
    required this.loadingRate,
    required this.icon,
    required this.gradientColors,
  });
}

class PricingResult {
  final VehicleSpec vehicle;
  final double baseFreight;
  final double fuelCost;
  final double loadingCost;
  final double subtotal;
  final double gstAmount;
  final double totalCost;
  final double chargeableWeight;
  final double volume;
  final bool isAvailable;
  final String unavailableReason;

  const PricingResult({
    required this.vehicle,
    required this.baseFreight,
    required this.fuelCost,
    required this.loadingCost,
    required this.subtotal,
    required this.gstAmount,
    required this.totalCost,
    required this.chargeableWeight,
    required this.volume,
    required this.isAvailable,
    this.unavailableReason = '',
  });

  String get formattedPrice => '₹${totalCost.toStringAsFixed(0)}';
  String get formattedBasePrice => '₹${subtotal.toStringAsFixed(0)}';
}

class PricingService {
  // Constants
  static const double fuelPrice = 105.0; // per liter
  static const double gstRate = 0.05; // 5% GST
  static const double volumetricDivisor = 6000.0; // kg per cubic meter

  // Vehicle specifications
  static const List<VehicleSpec> vehicles = [
    VehicleSpec(
      type: VehicleType.bike,
      name: 'Bike',
      description: 'Quick delivery for small items',
      weightCapacity: 5.0,
      volumeCapacity: 0.05, // 50 liters
      kmpl: 40.0,
      ratePerKm: 8.0,
      ratePerKg: 15.0,
      loadingRate: 50.0,
      icon: 'motorcycle',
      gradientColors: [0xFF4CAF50, 0xFF66BB6A],
    ),
    VehicleSpec(
      type: VehicleType.van,
      name: 'Small Van',
      description: 'Perfect for medium packages',
      weightCapacity: 500.0,
      volumeCapacity: 2.0, // 2 cubic meters
      kmpl: 15.0,
      ratePerKm: 12.0,
      ratePerKg: 8.0,
      loadingRate: 150.0,
      icon: 'airport_shuttle',
      gradientColors: [0xFF2196F3, 0xFF42A5F5],
    ),
    VehicleSpec(
      type: VehicleType.pickup,
      name: 'Pickup Truck',
      description: 'For larger deliveries',
      weightCapacity: 1000.0,
      volumeCapacity: 4.0, // 4 cubic meters
      kmpl: 12.0,
      ratePerKm: 18.0,
      ratePerKg: 6.0,
      loadingRate: 300.0,
      icon: 'local_shipping',
      gradientColors: [0xFF9C27B0, 0xFFBA68C8],
    ),
    VehicleSpec(
      type: VehicleType.truck,
      name: 'Large Truck',
      description: 'Heavy duty transportation',
      weightCapacity: 5000.0,
      volumeCapacity: 15.0, // 15 cubic meters
      kmpl: 8.0,
      ratePerKm: 25.0,
      ratePerKg: 4.0,
      loadingRate: 500.0,
      icon: 'local_shipping',
      gradientColors: [0xFFFF5722, 0xFFFF8A65],
    ),
  ];

  /// Calculate chargeable weight using the formula: max(actualWeight, (L*W*H)/6000)
  static double calculateChargeableWeight(double? actualWeight, PackageDimensions? dimensions) {
    final weight = actualWeight ?? 0.0;
    
    if (dimensions == null || !dimensions.isValid) {
      return weight;
    }

    // Convert dimensions from cm to meters and calculate volume
    final lengthM = (dimensions.length ?? 0.0) / 100.0;
    final widthM = (dimensions.width ?? 0.0) / 100.0;
    final heightM = (dimensions.height ?? 0.0) / 100.0;
    final volumeM3 = lengthM * widthM * heightM;
    
    // Calculate volumetric weight
    final volumetricWeight = (volumeM3 * 1000000) / volumetricDivisor; // convert back to kg
    
    return max(weight, volumetricWeight);
  }

  /// Calculate volume in cubic meters
  static double calculateVolume(PackageDimensions? dimensions) {
    if (dimensions == null || !dimensions.isValid) {
      return 0.0;
    }

    // Convert from cm to meters
    final lengthM = (dimensions.length ?? 0.0) / 100.0;
    final widthM = (dimensions.width ?? 0.0) / 100.0;
    final heightM = (dimensions.height ?? 0.0) / 100.0;
    
    return lengthM * widthM * heightM;
  }

  /// Calculate pricing for all vehicles based on package and distance
  static List<PricingResult> calculatePricing({
    required Package package,
    required double distanceKm,
    required bool selfLoading,
  }) {
    final chargeableWeight = calculateChargeableWeight(package.weight, package.dimensions);
    final volume = calculateVolume(package.dimensions);

    return vehicles.map((vehicle) {
      return _calculateVehiclePricing(
        vehicle: vehicle,
        chargeableWeight: chargeableWeight,
        volume: volume,
        distanceKm: distanceKm,
        selfLoading: selfLoading,
      );
    }).toList();
  }

  /// Calculate pricing for a specific vehicle
  static PricingResult _calculateVehiclePricing({
    required VehicleSpec vehicle,
    required double chargeableWeight,
    required double volume,
    required double distanceKm,
    required bool selfLoading,
  }) {
    // Check vehicle availability
    String unavailableReason = '';
    bool isAvailable = true;

    if (vehicle.weightCapacity < chargeableWeight) {
      isAvailable = false;
      unavailableReason = 'Weight exceeds capacity (${vehicle.weightCapacity}kg)';
    } else if (volume > vehicle.volumeCapacity) {
      isAvailable = false;
      unavailableReason = 'Volume exceeds capacity (${vehicle.volumeCapacity}m³)';
    }

    // Calculate costs (even for unavailable vehicles for comparison)
    
    // Choose between rate per km or rate per kg (use the higher one for better revenue)
    final rateKmCost = vehicle.ratePerKm * distanceKm;
    final rateKgCost = vehicle.ratePerKg * chargeableWeight;
    final baseFreight = max(rateKmCost, rateKgCost);

    // Calculate fuel cost
    final fuelCost = (distanceKm / vehicle.kmpl) * fuelPrice;

    // Calculate loading cost
    final loadingCost = selfLoading ? 0.0 : vehicle.loadingRate;

    // Calculate subtotal
    final subtotal = baseFreight + fuelCost + loadingCost;

    // Calculate GST
    final gstAmount = subtotal * gstRate;

    // Calculate total cost
    final totalCost = subtotal + gstAmount;

    return PricingResult(
      vehicle: vehicle,
      baseFreight: baseFreight,
      fuelCost: fuelCost,
      loadingCost: loadingCost,
      subtotal: subtotal,
      gstAmount: gstAmount,
      totalCost: totalCost,
      chargeableWeight: chargeableWeight,
      volume: volume,
      isAvailable: isAvailable,
      unavailableReason: unavailableReason,
    );
  }

  /// Get recommended vehicle (smallest capable vehicle or lowest cost)
  static PricingResult? getRecommendedVehicle(List<PricingResult> results) {
    final availableVehicles = results.where((result) => result.isAvailable).toList();
    
    if (availableVehicles.isEmpty) {
      return null;
    }

    // Sort by capacity first (smallest capable), then by cost
    availableVehicles.sort((a, b) {
      // First, compare by weight capacity (smaller is better)
      final capacityComparison = a.vehicle.weightCapacity.compareTo(b.vehicle.weightCapacity);
      if (capacityComparison != 0) {
        return capacityComparison;
      }
      
      // If same capacity, compare by total cost (cheaper is better)
      return a.totalCost.compareTo(b.totalCost);
    });

    return availableVehicles.first;
  }

  /// Format pricing breakdown for display
  static String formatPricingBreakdown(PricingResult result) {
    final buffer = StringBuffer();
    buffer.writeln('💰 Pricing Breakdown - ${result.vehicle.name}');
    buffer.writeln('─' * 40);
    buffer.writeln('📦 Chargeable Weight: ${result.chargeableWeight.toStringAsFixed(1)}kg');
    buffer.writeln('📐 Volume: ${result.volume.toStringAsFixed(3)}m³');
    buffer.writeln('');
    buffer.writeln('💵 Base Freight: ₹${result.baseFreight.toStringAsFixed(2)}');
    buffer.writeln('⛽ Fuel Cost: ₹${result.fuelCost.toStringAsFixed(2)}');
    
    if (result.loadingCost > 0) {
      buffer.writeln('🔧 Loading Cost: ₹${result.loadingCost.toStringAsFixed(2)}');
    }
    
    buffer.writeln('');
    buffer.writeln('📊 Subtotal: ₹${result.subtotal.toStringAsFixed(2)}');
    buffer.writeln('🏛️ GST (5%): ₹${result.gstAmount.toStringAsFixed(2)}');
    buffer.writeln('─' * 40);
    buffer.writeln('💳 Total: ${result.formattedPrice}');
    
    if (!result.isAvailable) {
      buffer.writeln('');
      buffer.writeln('❌ Unavailable: ${result.unavailableReason}');
    }
    
    return buffer.toString();
  }

  /// Calculate estimated delivery time based on distance and vehicle type
  static String getEstimatedTime(VehicleType vehicleType, double distanceKm) {
    // Average speeds for different vehicle types (km/h)
    const speeds = {
      VehicleType.bike: 25.0,
      VehicleType.van: 35.0,
      VehicleType.pickup: 40.0,
      VehicleType.truck: 45.0,
    };

    final speed = speeds[vehicleType] ?? 30.0;
    final timeHours = distanceKm / speed;
    
    if (timeHours < 1) {
      final minutes = (timeHours * 60).round();
      return '$minutes min';
    } else if (timeHours < 24) {
      final hours = timeHours.round();
      return '$hours hr';
    } else {
      final days = (timeHours / 24).round();
      return '$days day${days > 1 ? 's' : ''}';
    }
  }
}