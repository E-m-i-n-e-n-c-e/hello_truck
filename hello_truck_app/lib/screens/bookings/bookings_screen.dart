import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_truck_app/models/booking.dart';
import 'package:hello_truck_app/providers/booking_providers.dart';
import 'package:hello_truck_app/models/enums/booking_enums.dart';

class BookingsScreen extends ConsumerStatefulWidget {
  const BookingsScreen({super.key});

  @override
  ConsumerState<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends ConsumerState<BookingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'My Bookings',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'History'),
          ],
          labelColor: colorScheme.primary,
          unselectedLabelColor: colorScheme.onSurface.withValues(alpha: 0.6),
          indicatorColor: colorScheme.primary,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildActiveBookingsList(context),
          _buildHistoryBookingsList(context),
        ],
      ),
    );
  }

  Widget _buildActiveBookingsList(BuildContext context) {
    final activeBookingsAsync = ref.watch(activeBookingsProvider);

    return activeBookingsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade400, size: 48),
              const SizedBox(height: 12),
              Text('Failed to load active bookings', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text('$error', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(activeBookingsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (bookings) => _buildBookingsList(context, bookings, 'No active bookings', 'Your active bookings will appear here'),
    );
  }

  Widget _buildHistoryBookingsList(BuildContext context) {
    final historyBookingsAsync = ref.watch(bookingHistoryProvider);

    return historyBookingsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade400, size: 48),
              const SizedBox(height: 12),
              Text('Failed to load booking history', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text('$error', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(bookingHistoryProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (bookings) => _buildBookingsList(context, bookings, 'No past bookings', 'Your booking history will appear here'),
    );
  }

  Widget _buildBookingsList(BuildContext context, List<Booking> bookings, String emptyTitle, String emptySubtitle) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                size: 64,
                color: colorScheme.primary.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              emptyTitle,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              emptySubtitle,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final b = bookings[index];
        return _bookingCard(context, b);
      },
    );
  }

  Widget _bookingCard(BuildContext context, Booking b) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    Color statusColor;
    switch (b.status) {
      case BookingStatus.pending:
      case BookingStatus.driverAssigned:
      case BookingStatus.confirmed:
      case BookingStatus.pickupArrived:
      case BookingStatus.pickupVerified:
      case BookingStatus.inTransit:
      case BookingStatus.dropArrived:
      case BookingStatus.dropVerified:
        statusColor = Colors.orange;
        break;
      case BookingStatus.completed:
        statusColor = Colors.green;
        break;
      case BookingStatus.cancelled:
      case BookingStatus.expired:
        statusColor = Colors.red;
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '#${b.id.substring(0, 6).toUpperCase()}',
                  style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                  child: Text(
                    b.status.value.replaceAll('_', ' '),
                    style: textTheme.bodySmall?.copyWith(color: statusColor, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Icon(Icons.my_location, color: colorScheme.primary, size: 16),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 2,
                      height: 24,
                      child: DecoratedBox(
                        decoration: BoxDecoration(color: colorScheme.outline.withValues(alpha: 0.3)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Icon(Icons.location_on, color: Colors.red, size: 16),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(b.pickupAddress.formattedAddress, maxLines: 1, overflow: TextOverflow.ellipsis, style: textTheme.bodyMedium),
                      const SizedBox(height: 8),
                      Text(b.dropAddress.formattedAddress, maxLines: 1, overflow: TextOverflow.ellipsis, style: textTheme.bodyMedium),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.local_shipping_outlined, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(b.suggestedVehicleType.value.replaceAll('_', ' '), style: textTheme.bodySmall),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.payments_outlined, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text('₹${(b.finalCost ?? b.estimatedCost).toStringAsFixed(2)}', style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}