import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_truck_app/api/booking_api.dart' as booking_api;
import 'package:hello_truck_app/models/booking.dart';
import 'package:hello_truck_app/models/enums/booking_enums.dart';
import 'package:hello_truck_app/providers/auth_providers.dart';
import 'package:hello_truck_app/providers/booking_providers.dart';
import 'package:hello_truck_app/screens/bookings/booking_details_screen.dart';
import 'package:hello_truck_app/utils/nav_utils.dart';
import 'package:hello_truck_app/widgets/snackbars.dart';
import 'package:hello_truck_app/widgets/tappable_card.dart';
import 'package:hello_truck_app/utils/format_utils.dart';
import 'package:hello_truck_app/utils/date_time_utils.dart';

class BookingsScreen extends ConsumerStatefulWidget {
  const BookingsScreen({super.key});

  @override
  ConsumerState<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends ConsumerState<BookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Center(
                        child: Text(
                          'My Bookings',
                          style: tt.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Styled Tabs
                      Container(
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: cs.secondary.withValues(alpha: 0.1),
                            width: 1,
                          ),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: TabBar(
                          controller: _tabController,
                          indicatorSize: TabBarIndicatorSize.tab,
                          dividerColor: Colors.transparent,
                          indicator: BoxDecoration(
                            color: cs.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          labelColor: cs.onPrimary,
                          unselectedLabelColor: cs.onSurface.withValues(alpha: 0.7),
                          labelStyle: tt.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          unselectedLabelStyle: tt.labelLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                          overlayColor: WidgetStateProperty.all(Colors.transparent),
                          splashFactory: NoSplash.splashFactory,
                          tabs: const [
                            Tab(text: 'Active'),
                            Tab(text: 'History'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: [
              _ActiveBookingsTab(),
              _HistoryBookingsTab(),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveBookingsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeBookingsAsync = ref.watch(activeBookingsProvider);

    return activeBookingsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _buildErrorState(context, ref, error, activeBookingsProvider),
      data: (bookings) => _buildBookingsList(
        context,
        ref,
        bookings,
        'No active bookings',
        'Your active bookings will appear here',
        showCancel: true,
      ),
    );
  }
}

class _HistoryBookingsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyBookingsAsync = ref.watch(bookingHistoryProvider);

    return historyBookingsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _buildErrorState(context, ref, error, bookingHistoryProvider),
      data: (bookings) => _buildBookingsList(
        context,
        ref,
        bookings,
        'No past bookings',
        'Your booking history will appear here',
        showCancel: false,
      ),
    );
  }
}

Widget _buildErrorState(BuildContext context, WidgetRef ref, Object error, ProviderBase provider) {
  final cs = Theme.of(context).colorScheme;
  final tt = Theme.of(context).textTheme;

  return Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cs.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.error_outline_rounded, color: cs.error, size: 48),
          ),
          const SizedBox(height: 20),
          Text(
            'Failed to load bookings',
            style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            '$error',
            textAlign: TextAlign.center,
            style: tt.bodyMedium?.copyWith(color: cs.onSurface.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => ref.invalidate(provider),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    ),
  );
}

Widget _buildBookingsList(
  BuildContext context,
  WidgetRef ref,
  List<Booking> bookings,
  String emptyTitle,
  String emptySubtitle, {
  required bool showCancel,
}) {
  final cs = Theme.of(context).colorScheme;
  final tt = Theme.of(context).textTheme;

  if (bookings.isEmpty) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: cs.primary.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            emptyTitle,
            style: tt.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            emptySubtitle,
            style: tt.bodyMedium?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.6),
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
    separatorBuilder: (context, index) => const SizedBox(height: 12),
    itemBuilder: (context, index) => _BookingCard(
      booking: bookings[index],
      showCancel: showCancel,
    ),
  );
}

class _BookingCard extends ConsumerStatefulWidget {
  final Booking booking;
  final bool showCancel;

  const _BookingCard({required this.booking, required this.showCancel});

  @override
  ConsumerState<_BookingCard> createState() => _BookingCardState();
}

class _BookingCardState extends ConsumerState<_BookingCard> {
  bool _pickupExpanded = false;
  bool _dropExpanded = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final canCancel = widget.showCancel && showCancelOnCard(widget.booking.status);
    final statusColor = _getStatusColor(widget.booking.status, cs);

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceBright,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '#${widget.booking.bookingNumber.toString().padLeft(6, '0')}',
                        style: tt.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                            Icons.local_shipping_outlined,
                            size: 14,
                            color: cs.onSurface.withValues(alpha: 0.55),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.booking.assignedVehicle ?? widget.booking.idealVehicle,
                            style: tt.bodySmall?.copyWith(
                              color: cs.onSurface.withValues(alpha: 0.55),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Text(
                  (widget.booking.finalCost ?? widget.booking.estimatedCost).toRupees(),
                  style: tt.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Addresses with expand/collapse (times shown inline)
            _buildAddressSection(cs, tt),

            const SizedBox(height: 10),

            // Status row - Only this section is tappable
            Consumer(builder: (context, ref, _) {
              final stream = isActive(widget.booking.status)
                  ? ref.watch(driverNavigationStreamProvider(widget.booking.id))
                  : const AsyncValue.data(null);

              final label = tileLabel(widget.booking.status, stream.value);

              return TappableCard(
                pressedOpacity: 0.45,
                animationDuration: const Duration(milliseconds: 80),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => BookingDetailsScreen(initialBooking: widget.booking)),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.schedule_rounded, size: 18, color: statusColor),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          label,
                          style: tt.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: statusColor.withValues(alpha: 0.7),
                      ),
                    ],
                  ),
                ),
              );
            }),

            // Cancel button
            if (canCancel) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _showCancelDialog(context, ref),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: cs.error,
                    side: BorderSide(color: cs.error.withValues(alpha: 0.4)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Cancel Booking',
                    style: tt.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: cs.error,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAddressSection(ColorScheme cs, TextTheme tt) {
    return Column(
      children: [
        // Pickup row - tappable to expand (only show verified pickup time)
        _buildCompactAddressRow(cs, tt, cs.primary, widget.booking.pickupAddress.formattedAddress, widget.booking.pickupVerifiedAt, _pickupExpanded, () => setState(() => _pickupExpanded = !_pickupExpanded)),
        const SizedBox(height: 6),
        // Drop row - tappable to expand (only show verified drop time)
        _buildCompactAddressRow(cs, tt, Colors.red, widget.booking.dropAddress.formattedAddress, widget.booking.dropVerifiedAt, _dropExpanded, () => setState(() => _dropExpanded = !_dropExpanded)),
      ],
    );
  }

  Widget _buildCompactAddressRow(ColorScheme cs, TextTheme tt, Color dotColor, String address, DateTime? time, bool isExpanded, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            // Dot indicator
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            // Address text
            Expanded(
              child: Text(
                address,
                maxLines: isExpanded ? 3 : 1,
                overflow: TextOverflow.ellipsis,
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.85),
                  height: 1.2,
                ),
              ),
            ),
            // Time chip (show if available for both active and history)
            if (time != null) ...[
              const SizedBox(width: 8),
              Text(
                _formatTime(time),
                style: tt.labelSmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return DateTimeUtils.formatCompactDateTimeShort(dateTime);
  }

  /// Get status-specific color for booking status
  Color _getStatusColor(BookingStatus status, ColorScheme cs) {
    switch (status) {
      case BookingStatus.expired:
        return Colors.orange;
      case BookingStatus.cancelled:
        return cs.error;
      default:
        return cs.primary;
    }
  }

  Future<void> _showCancelDialog(BuildContext context, WidgetRef ref) async {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final config = await ref.read(cancellationConfigProvider.future);

    if (!context.mounted) return;
    final shouldCancel = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          // Watch navigation stream for real-time charge updates
          final navigationAsync = ref.watch(driverNavigationStreamProvider(widget.booking.id));
          final chargePercent = getCancellationChargePercent(
            booking: widget.booking,
            config: config,
            navigationAsync: navigationAsync,
          );

          // Use basePrice for cancellation charge calculation (matches server logic)
          final invoice = widget.booking.finalInvoice ?? widget.booking.estimateInvoice;
          final basePrice = invoice?.basePrice ?? widget.booking.estimatedCost;
          final walletApplied = invoice?.walletApplied ?? 0.0;
          final finalAmount = invoice?.finalAmount ?? widget.booking.estimatedCost;
          final totalPaid = walletApplied + finalAmount;

          final isConfirmed = widget.booking.status != BookingStatus.pending && widget.booking.status != BookingStatus.driverAssigned;
          final cancellationCharge = basePrice * chargePercent;

          // Proportional refund distribution (matches server logic)
          final walletRefund = totalPaid > 0 ? walletApplied - (cancellationCharge * walletApplied / totalPaid) : 0.0;
          final razorpayRefund = totalPaid > 0 ? finalAmount - (cancellationCharge * finalAmount / totalPaid) : 0.0;
          final refundAmount = walletRefund + razorpayRefund;

          return Container(
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cs.onSurface.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Title
                Text(
                  'Cancel Booking?',
                  style: tt.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Booking #${widget.booking.bookingNumber.toString().padLeft(6, '0')}',
                  style: tt.bodyMedium?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 20),

                // Refund details card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cs.surfaceBright,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cs.outline.withValues(alpha: 0.1)),
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow(context, 'Booking Amount', totalPaid.toRupees()),
                      if (cancellationCharge > 0) ...[
                        const SizedBox(height: 10),
                        _buildDetailRow(
                          context,
                          'Cancellation Fee',
                          '-${cancellationCharge.toRupees()}',
                          valueColor: cs.error,
                        ),
                      ],
                      const SizedBox(height: 10),
                      Divider(color: cs.outline.withValues(alpha: 0.1)),
                      const SizedBox(height: 10),
                      _buildDetailRow(
                        context,
                        'Refund Amount',
                        refundAmount.toRupees(),
                        valueColor: Colors.green,
                        isBold: true,
                      ),
                    ],
                  ),
                ),

                if (isConfirmed) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded, size: 18, color: Colors.orange),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Cancellation charges increase with distance travelled after driver accepts',
                            style: tt.bodySmall?.copyWith(color: Colors.orange.shade800),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Keep Booking'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: FilledButton.styleFrom(
                          backgroundColor: cs.error,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Cancel Booking'),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
              ],
            ),
          );
        },
      ),
    );

    if (shouldCancel == true && context.mounted) {
      await _cancelBooking(context, ref);
    }
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
    bool isBold = false,
  }) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: tt.bodyMedium?.copyWith(
            color: cs.onSurface.withValues(alpha: 0.7),
            fontWeight: isBold ? FontWeight.w600 : null,
          ),
        ),
        Text(
          value,
          style: tt.bodyMedium?.copyWith(
            color: valueColor ?? cs.onSurface,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Future<void> _cancelBooking(BuildContext context, WidgetRef ref) async {
    try {
      final api = ref.read(apiProvider).value!;
      await booking_api.cancelBooking(api, widget.booking.id, 'Booking cancelled by customer');
      ref.invalidate(activeBookingsProvider);
      ref.invalidate(bookingHistoryProvider);
      if (context.mounted) {
        SnackBars.success(context, 'Booking cancelled successfully');
      }
    } catch (e) {
      if (context.mounted) {
        SnackBars.error(context, 'Failed to cancel booking: $e');
      }
    }
  }
}