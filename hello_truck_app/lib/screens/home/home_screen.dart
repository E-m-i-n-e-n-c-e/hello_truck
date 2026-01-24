import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_truck_app/models/booking.dart';
import 'package:hello_truck_app/models/customer.dart';
import 'package:hello_truck_app/models/enums/booking_enums.dart';
import 'package:hello_truck_app/providers/addresse_providers.dart';
import 'package:hello_truck_app/providers/booking_providers.dart';
import 'package:hello_truck_app/providers/customer_providers.dart';
import 'package:hello_truck_app/providers/referral_providers.dart';
import 'package:hello_truck_app/providers/auth_providers.dart';
import 'package:hello_truck_app/api/customer_api.dart' as customer_api;
import 'package:hello_truck_app/screens/home/booking/address_selection_screen.dart';
import 'package:hello_truck_app/widgets/gst_details_modal.dart';
import 'package:hello_truck_app/screens/profile/gst_details_screen.dart';
import 'package:hello_truck_app/screens/profile/referral_screen.dart';
import 'package:hello_truck_app/screens/profile/saved_addresses_screen.dart';
import 'package:hello_truck_app/utils/date_time_utils.dart';
import 'package:hello_truck_app/utils/format_utils.dart';
import 'package:hello_truck_app/widgets/tappable_card.dart';
import 'package:hello_truck_app/widgets/snackbars.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final customerAsync = ref.watch(customerProvider);
    final historyAsync = ref.watch(bookingHistoryProvider);

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting
              _buildGreeting(context, customerAsync),
              const SizedBox(height: 28),

              // Book Now CTA
              _buildBookNowCard(context),
              const SizedBox(height: 24),

              // Quick Links (moved to top)
              _buildQuickLinks(context, ref),
              const SizedBox(height: 24),

              // Apply Referral Code Card (only show if within 24 hours and no referral code applied)
              if (_shouldShowApplyReferralCard(customerAsync)) ...[
                _buildApplyReferralCard(context, ref),
                const SizedBox(height: 24),
              ],

              // Recent Bookings
              historyAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
                data: (bookings) {
                  // Filter completed bookings from last 48 hours (in IST)
                  final nowIST = DateTimeUtils.nowIST();
                  final fortyEightHoursAgo = nowIST.subtract(const Duration(hours: 48));

                  final recentCompleted = bookings.where((b) {
                    if (b.status != BookingStatus.completed) return false;
                    final completedAt = b.completedAt ?? b.createdAt;
                    final completedAtIST = DateTimeUtils.toIST(completedAt);
                    return completedAtIST.isAfter(fortyEightHoursAgo);
                  }).toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(context, 'Recent Bookings'),
                      const SizedBox(height: 12),
                      if (recentCompleted.isEmpty)
                        _buildEmptyBookingsState(context)
                      else
                        ...recentCompleted.map((b) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _buildRecentBookingCard(context, b),
                        )),
                    ],
                  );
                },
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildGreeting(BuildContext context, AsyncValue customerAsync) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final name = customerAsync.valueOrNull?.firstName ?? '';

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello${name.isNotEmpty ? ', $name' : ''} 👋',
                style: tt.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Ready to ship your parcel?',
                style: tt.bodyMedium?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(Icons.local_shipping_rounded, color: cs.primary.withValues(alpha: 0.9), size: 24),
        ),
      ],
    );
  }


  Widget _buildBookNowCard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return TappableCard(
      pressedOpacity: 0.85,
      animationDuration: const Duration(milliseconds: 100),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddressSelectionScreen()),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: cs.primary,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Book Parcel Transportation',
                      style: tt.titleLarge?.copyWith(
                        color: cs.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Quick & easy booking',
                      style: tt.bodyMedium?.copyWith(
                        color: cs.onPrimary.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_rounded, color: cs.onPrimary, size: 24),
            ],
          ),
        ),
      ),
    );
  }

  bool _shouldShowApplyReferralCard(AsyncValue<Customer> customerAsync) {
    return customerAsync.whenOrNull(
      data: (customer) {
        // Don't show if customer already applied a referral code
        if (customer.hasAppliedReferral) {
          return false;
        }

        // Check if within 24 hours of profile creation
        final memberSince = customer.memberSince;
        final now = DateTime.now();
        final difference = now.difference(memberSince);
        return difference.inHours < 24;
      },
    ) ?? false;
  }

  Widget _buildApplyReferralCard(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return TappableCard(
      pressedOpacity: 0.6,
      animationDuration: const Duration(milliseconds: 100),
      onTap: () => _showApplyReferralBottomSheet(context, ref),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.redeem_rounded, size: 24, color: cs.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Have a referral code?',
                    style: tt.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Apply here to get ₹50',
                    style: tt.bodySmall?.copyWith(
                      color: cs.primary.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: cs.primary.withValues(alpha: 0.8),
            ),
          ],
        ),
      ),
    );
  }

  void _showApplyReferralBottomSheet(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final controller = TextEditingController();
    bool isLoading = false;
    String? errorText;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 20,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Apply Referral Code',
                            style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(bottomSheetContext),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter a referral code to get ₹50 in your wallet',
                      style: tt.bodyMedium?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: controller,
                      enabled: !isLoading,
                      decoration: InputDecoration(
                        labelText: 'Referral Code',
                        hintText: 'CUS-XXXXXXXX',
                        errorText: errorText,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.card_giftcard_rounded),
                      ),
                      textCapitalization: TextCapitalization.characters,
                      onChanged: (value) {
                        if (errorText != null) {
                          setModalState(() {
                            errorText = null;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: isLoading
                            ? null
                            : () async {
                                final code = controller.text.trim().toUpperCase();
                                if (code.isEmpty) {
                                  setModalState(() {
                                    errorText = 'Please enter a referral code';
                                  });
                                  return;
                                }

                                setModalState(() {
                                  isLoading = true;
                                  errorText = null;
                                });

                                try {
                                  final api = ref.read(apiProvider).value!;

                                  await customer_api.applyReferralCode(api, code);
                                  ref.invalidate(customerProvider);
                                  ref.invalidate(referralStatsProvider);

                                  if (bottomSheetContext.mounted) {
                                    Navigator.pop(bottomSheetContext);
                                  }
                                  if (context.mounted) {
                                    SnackBars.success(context, 'Referral code applied! ₹50 added to wallet');
                                  }
                                } catch (e) {
                                    final message = e.toString();

                                    if (bottomSheetContext.mounted) {
                                    Navigator.pop(bottomSheetContext);
                                    }
                                    if (context.mounted) {
                                    SnackBars.error(context, message);
                                    }
                                }
                              },
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text('Apply Code'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, {VoidCallback? onSeeAll}) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: tt.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'See all',
              style: tt.bodyMedium?.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyBookingsState(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      decoration: BoxDecoration(
        color: cs.surfaceBright,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outline.withValues(alpha: 0.1)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                size: 48,
                color: cs.primary.withValues(alpha: 0.7),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No recent bookings',
            textAlign: TextAlign.center,
            style: tt.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your recent bookings appear here',
            style: tt.bodyMedium?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentBookingCard(BuildContext context, Booking booking) {
    return _ExpandableBookingCard(booking: booking);
  }

  Widget _buildQuickLinks(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: tt.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildQuickLinkCard(
                context,
                icon: Icons.location_on_rounded,
                label: 'Addresses',
                color: cs.primary,
                onTap: () {
                  ref.invalidate(savedAddressesProvider);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SavedAddressesScreen()),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildGstQuickLinkCard(context, ref),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildQuickLinkCard(
                context,
                icon: Icons.card_giftcard_rounded,
                label: 'Refer',
                color: Colors.orange,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ReferralScreen()),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGstQuickLinkCard(BuildContext context, WidgetRef ref) {
    final gstDetailsAsync = ref.watch(gstDetailsProvider);

    return gstDetailsAsync.when(
      loading: () => _buildQuickLinkCard(
        context,
        icon: Icons.receipt_long_rounded,
        label: 'GST',
        color: Colors.green,
        onTap: () {},
      ),
      error: (_, _) => _buildQuickLinkCard(
        context,
        icon: Icons.receipt_long_rounded,
        label: 'Add GST',
        color: Colors.green,
        onTap: () {
          GstDetailsModal.show(
            context,
            navigateToScreenAfterAdd: true,
            onSuccess: () {
              ref.invalidate(gstDetailsProvider);
              SnackBars.success(context, 'GST details added successfully');
            },
          );
        },
      ),
      data: (gstDetails) {
        final hasGstDetails = gstDetails.isNotEmpty;

        return _buildQuickLinkCard(
          context,
          icon: Icons.receipt_long_rounded,
          label: hasGstDetails ? 'Manage GST' : 'Add GST',
          color: Colors.green,
          onTap: () {
            if (hasGstDetails) {
              // Navigate to manage screen
              ref.invalidate(gstDetailsProvider);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GstDetailsScreen()),
              );
            } else {
              // Open modal to add
              GstDetailsModal.show(
                context,
                navigateToScreenAfterAdd: true,
                onSuccess: () {
                  ref.invalidate(gstDetailsProvider);
                  SnackBars.success(context, 'GST details added successfully');
                },
              );
            }
          },
        );
      },
    );
  }

  Widget _buildQuickLinkCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return TappableCard(
      pressedOpacity: 0.6,
      animationDuration: const Duration(milliseconds: 100),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: cs.surfaceBright,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outline.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: cs.shadow.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: tt.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Expandable booking card widget with its own state
class _ExpandableBookingCard extends StatefulWidget {
  final Booking booking;

  const _ExpandableBookingCard({required this.booking});

  @override
  State<_ExpandableBookingCard> createState() => _ExpandableBookingCardState();
}

class _ExpandableBookingCardState extends State<_ExpandableBookingCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final booking = widget.booking;

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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Compact header - always visible
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '#${booking.bookingNumber.toString().padLeft(6, '0')}',
                        style: tt.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          (booking.finalCost ?? booking.estimatedCost).toRupees(),
                          style: tt.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: cs.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateTimeUtils.formatShortDateIST(booking.completedAt ?? booking.createdAt),
                          style: tt.labelSmall?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 4),
                    AnimatedRotation(
                      turns: _isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: cs.onSurface.withValues(alpha: 0.4),
                        size: 20,
                      ),
                    ),
                  ],
                ),

                // Expandable details section
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Pickup and Drop addresses
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            children: [
                              // Pickup Address
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.radio_button_checked, color: Colors.green, size: 12),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Pickup',
                                          style: tt.labelSmall?.copyWith(
                                            color: cs.onSurface.withValues(alpha: 0.5),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          booking.pickupAddress.formattedAddress,
                                          style: tt.bodySmall?.copyWith(
                                            color: cs.onSurface.withValues(alpha: 0.8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              // Dotted line connector
                              Padding(
                                padding: const EdgeInsets.only(left: 9),
                                child: Row(
                                  children: [
                                    Column(
                                      children: List.generate(3, (index) =>
                                        Container(
                                          width: 2,
                                          height: 4,
                                          margin: const EdgeInsets.symmetric(vertical: 1),
                                          decoration: BoxDecoration(
                                            color: cs.onSurface.withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(1),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Drop Address
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: cs.primary.withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.location_on, color: cs.primary, size: 12),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Drop',
                                          style: tt.labelSmall?.copyWith(
                                            color: cs.onSurface.withValues(alpha: 0.5),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          booking.dropAddress.formattedAddress,
                                          style: tt.bodySmall?.copyWith(
                                            color: cs.onSurface.withValues(alpha: 0.8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Package, Vehicle, and Distance info row
                        Row(
                          children: [
                            // Vehicle info
                            Expanded(
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.local_shipping_outlined,
                                    size: 16,
                                    color: cs.onSurface.withValues(alpha: 0.5),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      booking.assignedVehicle ?? booking.idealVehicle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: tt.bodySmall?.copyWith(
                                        color: cs.onSurface.withValues(alpha: 0.7),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Distance info
                            if (booking.distanceKm > 0) ...[
                              const SizedBox(width: 12),
                              Row(
                                children: [
                                  Icon(
                                    Icons.straighten_rounded,
                                    size: 16,
                                    color: cs.onSurface.withValues(alpha: 0.5),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    booking.distanceKm.toDistance(),
                                    style: tt.bodySmall?.copyWith(
                                      color: cs.onSurface.withValues(alpha: 0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 200),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
