import 'package:hello_truck_app/auth/api.dart';
import 'package:hello_truck_app/models/package.dart';
import 'package:hello_truck_app/models/saved_address.dart';
import 'package:hello_truck_app/services/pricing_service.dart';

// Order status enum
enum OrderStatus {
  pending,
  confirmed,
  driverAssigned,
  driverEnRoute,
  pickupCompleted,
  inTransit,
  delivered,
  cancelled,
  failed
}

// Order model for API responses
class Order {
  final String id;
  final String customerId;
  final Package package;
  final Address pickupAddress;
  final Address deliveryAddress;
  final VehicleType vehicleType;
  final double totalCost;
  final OrderStatus status;
  final String? driverId;
  final String? driverName;
  final String? driverPhone;
  final String? vehicleNumber;
  final double distanceKm;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? estimatedPickupTime;
  final DateTime? estimatedDeliveryTime;
  final DateTime? actualPickupTime;
  final DateTime? actualDeliveryTime;
  final String? cancellationReason;
  final Map<String, dynamic>? metadata;

  const Order({
    required this.id,
    required this.customerId,
    required this.package,
    required this.pickupAddress,
    required this.deliveryAddress,
    required this.vehicleType,
    required this.totalCost,
    required this.status,
    this.driverId,
    this.driverName,
    this.driverPhone,
    this.vehicleNumber,
    required this.distanceKm,
    required this.createdAt,
    required this.updatedAt,
    this.estimatedPickupTime,
    this.estimatedDeliveryTime,
    this.actualPickupTime,
    this.actualDeliveryTime,
    this.cancellationReason,
    this.metadata,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      customerId: json['customerId'],
      package: Package.fromJson(json['package']),
      pickupAddress: Address.fromJson(json['pickupAddress']),
      deliveryAddress: Address.fromJson(json['deliveryAddress']),
      vehicleType: VehicleType.values.firstWhere(
        (e) => e.name == json['vehicleType'],
        orElse: () => VehicleType.van,
      ),
      totalCost: (json['totalCost'] as num).toDouble(),
      status: OrderStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => OrderStatus.pending,
      ),
      driverId: json['driverId'],
      driverName: json['driverName'],
      driverPhone: json['driverPhone'],
      vehicleNumber: json['vehicleNumber'],
      distanceKm: (json['distanceKm'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      estimatedPickupTime: json['estimatedPickupTime'] != null
          ? DateTime.parse(json['estimatedPickupTime'])
          : null,
      estimatedDeliveryTime: json['estimatedDeliveryTime'] != null
          ? DateTime.parse(json['estimatedDeliveryTime'])
          : null,
      actualPickupTime: json['actualPickupTime'] != null
          ? DateTime.parse(json['actualPickupTime'])
          : null,
      actualDeliveryTime: json['actualDeliveryTime'] != null
          ? DateTime.parse(json['actualDeliveryTime'])
          : null,
      cancellationReason: json['cancellationReason'],
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'package': package.toJson(),
      'pickupAddress': pickupAddress.toJson(),
      'deliveryAddress': deliveryAddress.toJson(),
      'vehicleType': vehicleType.name,
      'totalCost': totalCost,
      'status': status.name,
      'driverId': driverId,
      'driverName': driverName,
      'driverPhone': driverPhone,
      'vehicleNumber': vehicleNumber,
      'distanceKm': distanceKm,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'estimatedPickupTime': estimatedPickupTime?.toIso8601String(),
      'estimatedDeliveryTime': estimatedDeliveryTime?.toIso8601String(),
      'actualPickupTime': actualPickupTime?.toIso8601String(),
      'actualDeliveryTime': actualDeliveryTime?.toIso8601String(),
      'cancellationReason': cancellationReason,
      'metadata': metadata,
    };
  }
}

// Create order request model
class CreateOrderRequest {
  final Package package;
  final Address pickupAddress;
  final Address deliveryAddress;
  final VehicleType vehicleType;
  final double distanceKm;
  final DateTime? preferredPickupTime;
  final Map<String, dynamic>? metadata;

  const CreateOrderRequest({
    required this.package,
    required this.pickupAddress,
    required this.deliveryAddress,
    required this.vehicleType,
    required this.distanceKm,
    this.preferredPickupTime,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'package': package.toJson(),
      'pickupAddress': pickupAddress.toJson(),
      'deliveryAddress': deliveryAddress.toJson(),
      'vehicleType': vehicleType.name,
      'distanceKm': distanceKm,
      'preferredPickupTime': preferredPickupTime?.toIso8601String(),
      'metadata': metadata,
    };
  }
}

/// Get all orders for the current customer
Future<List<Order>> getOrders(API api, {
  OrderStatus? status,
  int? limit,
  int? offset,
}) async {
  final queryParams = <String, dynamic>{};
  if (status != null) queryParams['status'] = status.name;
  if (limit != null) queryParams['limit'] = limit;
  if (offset != null) queryParams['offset'] = offset;

  final query = queryParams.isNotEmpty
      ? '?${queryParams.entries.map((e) => '${e.key}=${e.value}').join('&')}'
      : '';

  final response = await api.get('/orders$query');
  return (response.data as List).map((json) => Order.fromJson(json)).toList();
}

/// Get a specific order by ID
Future<Order> getOrderById(API api, String orderId) async {
  final response = await api.get('/orders/$orderId');
  return Order.fromJson(response.data);
}

/// Create a new transportation order
Future<Order> createOrder(API api, CreateOrderRequest request) async {
  final response = await api.post('/orders', data: request.toJson());
  return Order.fromJson(response.data);
}

/// Get real-time pricing for an order before creation
Future<PricingResult> getOrderPricing(API api, {
  required Package package,
  required double distanceKm,
  required VehicleType vehicleType,
  bool selfLoading = false,
}) async {
  final response = await api.post('/orders/pricing', data: {
    'package': package.toJson(),
    'distanceKm': distanceKm,
    'vehicleType': vehicleType.name,
    'selfLoading': selfLoading,
  });

  // Parse the API response to PricingResult
  final data = response.data;
  final vehicle = PricingService.vehicles.firstWhere((v) => v.type == vehicleType);

  return PricingResult(
    vehicle: vehicle,
    totalCost: (data['totalCost'] as num).toDouble(),
    isAvailable: data['isAvailable'] ?? true,
    unavailableReason: data['unavailableReason'] ?? '',
    baseFreight: (data['baseFreight'] as num).toDouble(),
    fuelCost: (data['fuelCost'] as num).toDouble(),
    loadingCost: (data['loadingCost'] as num).toDouble(),
    gstAmount: (data['gstAmount'] as num).toDouble(),
    subtotal: (data['subtotal'] as num?)?.toDouble() ?? ((data['baseFreight'] as num).toDouble() + (data['fuelCost'] as num).toDouble() + (data['loadingCost'] as num).toDouble()),
    chargeableWeight: (data['chargeableWeight'] as num?)?.toDouble() ?? 0.0,
    volume: (data['volume'] as num?)?.toDouble() ?? 0.0,
  );
}

/// Update order status (typically called by driver app or admin)
Future<Order> updateOrderStatus(API api, String orderId, OrderStatus status, {
  String? notes,
  Map<String, dynamic>? metadata,
}) async {
  final response = await api.patch('/orders/$orderId/status', data: {
    'status': status.name,
    if (notes != null) 'notes': notes,
    if (metadata != null) 'metadata': metadata,
  });
  return Order.fromJson(response.data);
}

/// Cancel an order
Future<Order> cancelOrder(API api, String orderId, {
  required String reason,
}) async {
  final response = await api.patch('/orders/$orderId/cancel', data: {
    'reason': reason,
  });
  return Order.fromJson(response.data);
}

/// Track order location (get real-time driver location)
Future<Map<String, dynamic>> trackOrder(API api, String orderId) async {
  final response = await api.get('/orders/$orderId/track');
  return {
    'driverLocation': response.data['driverLocation'],
    'estimatedArrival': response.data['estimatedArrival'],
    'currentStatus': response.data['currentStatus'],
    'lastUpdated': DateTime.parse(response.data['lastUpdated']),
  };
}

/// Rate and review an order after completion
Future<void> rateOrder(API api, String orderId, {
  required int rating, // 1-5 stars
  String? review,
  String? feedback,
}) async {
  await api.post('/orders/$orderId/rate', data: {
    'rating': rating,
    if (review != null) 'review': review,
    if (feedback != null) 'feedback': feedback,
  });
}

/// Get order history with pagination
Future<Map<String, dynamic>> getOrderHistory(API api, {
  int page = 1,
  int limit = 20,
  OrderStatus? status,
  DateTime? fromDate,
  DateTime? toDate,
}) async {
  final queryParams = <String, dynamic>{
    'page': page,
    'limit': limit,
  };

  if (status != null) queryParams['status'] = status.name;
  if (fromDate != null) queryParams['fromDate'] = fromDate.toIso8601String();
  if (toDate != null) queryParams['toDate'] = toDate.toIso8601String();

  final query = '?${queryParams.entries.map((e) => '${e.key}=${e.value}').join('&')}';

  final response = await api.get('/orders/history$query');

  return {
    'orders': (response.data['orders'] as List)
        .map((json) => Order.fromJson(json))
        .toList(),
    'totalCount': response.data['totalCount'],
    'currentPage': response.data['currentPage'],
    'totalPages': response.data['totalPages'],
    'hasNextPage': response.data['hasNextPage'],
    'hasPreviousPage': response.data['hasPreviousPage'],
  };
}

/// Get order statistics/analytics
Future<Map<String, dynamic>> getOrderStats(API api, {
  DateTime? fromDate,
  DateTime? toDate,
}) async {
  final queryParams = <String, dynamic>{};
  if (fromDate != null) queryParams['fromDate'] = fromDate.toIso8601String();
  if (toDate != null) queryParams['toDate'] = toDate.toIso8601String();

  final query = queryParams.isNotEmpty
      ? '?${queryParams.entries.map((e) => '${e.key}=${e.value}').join('&')}'
      : '';

  final response = await api.get('/orders/stats$query');
  return response.data;
}

/// Upload package images for an order
Future<void> uploadOrderImages(API api, String orderId, {
  String? packageImagePath,
  String? gstBillImagePath,
  List<String>? additionalImages,
}) async {
  final data = <String, dynamic>{};

  if (packageImagePath != null) data['packageImage'] = packageImagePath;
  if (gstBillImagePath != null) data['gstBillImage'] = gstBillImagePath;
  if (additionalImages != null) data['additionalImages'] = additionalImages;

  await api.post('/orders/$orderId/images', data: data);
}

/// Get available vehicles and pricing for a route
Future<List<PricingResult>> getAvailableVehicles(API api, {
  required Package package,
  required double distanceKm,
  required double pickupLatitude,
  required double pickupLongitude,
  required double deliveryLatitude,
  required double deliveryLongitude,
  bool selfLoading = false,
}) async {
  final response = await api.post('/orders/available-vehicles', data: {
    'package': package.toJson(),
    'distanceKm': distanceKm,
    'pickupLocation': {
      'latitude': pickupLatitude,
      'longitude': pickupLongitude,
    },
    'deliveryLocation': {
      'latitude': deliveryLatitude,
      'longitude': deliveryLongitude,
    },
    'selfLoading': selfLoading,
  });

  // Convert API response to PricingResult list
  return (response.data as List).map((vehicleData) {
    final vehicleType = VehicleType.values.firstWhere(
      (v) => v.name == vehicleData['vehicleType'],
      orElse: () => VehicleType.van,
    );
    final vehicle = PricingService.vehicles.firstWhere((v) => v.type == vehicleType);

    return PricingResult(
      vehicle: vehicle,
      totalCost: (vehicleData['totalCost'] as num).toDouble(),
      isAvailable: vehicleData['isAvailable'] ?? true,
      unavailableReason: vehicleData['unavailableReason'] ?? '',
      baseFreight: (vehicleData['baseFreight'] as num).toDouble(),
      fuelCost: (vehicleData['fuelCost'] as num).toDouble(),
      loadingCost: (vehicleData['loadingCost'] as num).toDouble(),
      gstAmount: (vehicleData['gstAmount'] as num).toDouble(),
      subtotal: (vehicleData['subtotal'] as num?)?.toDouble() ?? ((vehicleData['baseFreight'] as num).toDouble() + (vehicleData['fuelCost'] as num).toDouble() + (vehicleData['loadingCost'] as num).toDouble()),
      chargeableWeight: (vehicleData['chargeableWeight'] as num?)?.toDouble() ?? 0.0,
      volume: (vehicleData['volume'] as num?)?.toDouble() ?? 0.0,
    );
  }).toList();
}
