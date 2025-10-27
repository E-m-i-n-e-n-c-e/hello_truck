import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_truck_app/models/booking.dart';
import 'package:hello_truck_app/providers/booking_providers.dart';
import 'package:hello_truck_app/screens/bookings/booking_details_screen.dart';
import 'package:hello_truck_app/utils/nav_utils.dart';

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

    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => BookingDetailsScreen(initialBooking: b)));
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceBright,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: colorScheme.shadow.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Booking number and price
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Booking #${b.bookingNumber.toString().padLeft(6, '0')}',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.local_shipping_outlined, size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 6),
                          Text(
                            b.suggestedVehicleType.value.replaceAll('_', ' '),
                            style: textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Text(
                    '₹${(b.finalCost ?? b.estimatedCost).toStringAsFixed(0)}',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Live ETA row powered by SSE
              Consumer(builder: (context, ref, _) {

                final stream = isActive(b.status) ? ref.watch(driverNavigationStreamProvider(b.id)) : AsyncValue.data(null);

                final label = tileLabel(b.status, stream.value);
                final hint = isBeforeDropArrived(b.status)
                    ? 'Time to drop: ${formatTime(stream.value?.timeToDrop ?? 0)}\nDistance to drop: ${formatDistance(stream.value?.distanceToDrop ?? 0)}'
                    : null;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main ETA status
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.schedule, size: 20, color: colorScheme.primary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              label,
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios, size: 16, color: colorScheme.primary),
                        ],
                      ),
                    ),
                    // Hint text below if available
                    if (hint != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          hint,
                          style: textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}