import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_truck_app/models/customer.dart';
import 'package:hello_truck_app/providers/auth_providers.dart';
import 'package:hello_truck_app/providers/customer_providers.dart';
import 'package:hello_truck_app/providers/addresse_providers.dart';
import 'package:hello_truck_app/api/customer_api.dart' as customer_api;
import 'package:hello_truck_app/widgets/snackbars.dart';
import 'package:hello_truck_app/widgets/tappable_card.dart';
import 'package:hello_truck_app/screens/profile/profile_edit_dialogs.dart';
import 'package:hello_truck_app/screens/profile/email_link_dialog.dart';
import 'package:hello_truck_app/screens/profile/wallet_activity_screen.dart';
import 'package:hello_truck_app/screens/profile/payments_screen.dart';
import 'package:hello_truck_app/screens/profile/gst_details_screen.dart';
import 'package:hello_truck_app/widgets/gst_details_modal.dart';
import 'package:hello_truck_app/screens/profile/referral_screen.dart';
import 'package:hello_truck_app/screens/profile/saved_addresses_screen.dart';
import 'package:hello_truck_app/utils/date_time_utils.dart';
import 'package:hello_truck_app/utils/format_utils.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isGstWarningDismissed = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final customerAsync = ref.watch(customerProvider);

    return Scaffold(
      backgroundColor: cs.surface,
      body: customerAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 3)),
        error: (error, stack) => _buildErrorState(context, error),
        data: (customer) => _buildProfileContent(context, customer),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
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
              'Failed to load profile',
              style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: tt.bodyMedium?.copyWith(color: cs.onSurface.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => ref.invalidate(customerProvider),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context, Customer customer) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return SafeArea(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Profile',
              style: tt.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 24),

            // Profile Card
            _buildProfileCard(context, customer),
            const SizedBox(height: 20),

            // GST Warning (if no GST details)
            _buildGstWarning(context),

            // Wallet Balance Card
            _buildWalletBalanceCard(context, customer),
            const SizedBox(height: 20),

            // Quick Access Section
            _buildQuickAccessSection(context),
            const SizedBox(height: 24),

            // Personal Information Section
            _buildSectionHeader(context, 'Personal Information'),
            const SizedBox(height: 12),
            _buildPersonalInfoSection(context, customer),
            const SizedBox(height: 24),

            // Account Section
            _buildSectionHeader(context, 'Account'),
            const SizedBox(height: 12),
            _buildAccountSection(context, customer),
            const SizedBox(height: 24),

            // Logout Button
            _buildLogoutButton(context),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, Customer customer) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceBright,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Profile Avatar
          CircleAvatar(
            radius: 40,
            backgroundColor: cs.primary.withValues(alpha: 0.15),
            child: Text(
              customer.initials,
              style: tt.headlineSmall?.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Profile Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer.fullName.isNotEmpty ? customer.fullName : 'Hello User',
                  style: tt.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  customer.phoneNumber,
                  style: tt.bodyMedium?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                if (customer.email.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    customer.email,
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
                if (customer.isBusiness) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.business_rounded, size: 14, color: cs.primary),
                        const SizedBox(width: 4),
                        Text(
                          'Business Account',
                          style: tt.labelSmall?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGstWarning(BuildContext context) {
    if (_isGstWarningDismissed) {
      return const SizedBox.shrink();
    }

    final gstDetailsAsync = ref.watch(gstDetailsProvider);

    return gstDetailsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (gstDetails) {
        // Don't show warning if GST details exist
        if (gstDetails.isNotEmpty) {
          return const SizedBox.shrink();
        }

        final cs = Theme.of(context).colorScheme;
        final tt = Theme.of(context).textTheme;
        final color = Colors.orange;

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.info_rounded,
                      color: color,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add GST Details',
                          style: tt.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Add your GST details to save ₹20 platform fee on your bookings.',
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _isGstWarningDismissed = true;
                      });
                    },
                    icon: Icon(
                      Icons.close_rounded,
                      color: cs.onSurface.withValues(alpha: 0.5),
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }

  Widget _buildWalletBalanceCard(BuildContext context, Customer customer) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return TappableCard(
      pressedOpacity: 0.85,
      animationDuration: const Duration(milliseconds: 100),
      onTap: () {
        ref.invalidate(walletLogsProvider);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const WalletActivityScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cs.primary,
              cs.primary.withValues(alpha: 0.85),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cs.onPrimary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.account_balance_wallet_rounded,
                color: cs.onPrimary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Wallet Balance',
                    style: tt.labelMedium?.copyWith(
                      color: cs.onPrimary.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    customer.walletBalance.toRupees(),
                    style: tt.titleLarge?.copyWith(
                      color: cs.onPrimary,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: cs.onPrimary.withValues(alpha: 0.7),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAccessSection(BuildContext context) {
    return Column(
      children: [
        // GST Details Card with Plus Button
        _buildGstDetailsCard(context, ref),
        const SizedBox(height: 12),

        // Payments Card
        _buildQuickAccessCard(
          context,
          icon: Icons.payment_rounded,
          title: 'Payments',
          subtitle: 'Transactions & pending refunds',
          onTap: () {
            ref.invalidate(transactionLogsProvider);
            ref.invalidate(pendingRefundsProvider);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PaymentsScreen()),
            );
          },
        ),
        const SizedBox(height: 12),

        // Saved Addresses Card
        _buildQuickAccessCard(
          context,
          icon: Icons.location_on_rounded,
          title: 'Saved Addresses',
          subtitle: 'Manage your saved locations',
          onTap: () {
            ref.invalidate(savedAddressesProvider);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SavedAddressesScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildGstDetailsCard(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final gstDetailsAsync = ref.watch(gstDetailsProvider);
    return gstDetailsAsync.when(
      loading: () => _buildGstCardSkeleton(context),
      error: (_, _) => _buildGstCardSkeleton(context),
      data: (gstDetails) {
        final hasGstDetails = gstDetails.isNotEmpty;

        return TappableCard(
          pressedOpacity: 0.6,
          animationDuration: const Duration(milliseconds: 100),
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
          child: Container(
            decoration: BoxDecoration(
              color: cs.surfaceBright,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: hasGstDetails
                    ? Colors.transparent
                    : cs.primary.withValues(alpha: 0.3),
                width: hasGstDetails ? 0 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: cs.shadow.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.receipt_long_rounded, color: cs.primary, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'GST Details',
                          style: tt.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          hasGstDetails ? 'Manage your business GST info' : 'Add GST Details',
                          style: tt.bodyMedium?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Show plus icon if no GST, chevron if has GST
                  Icon(
                    hasGstDetails ? Icons.chevron_right_rounded : Icons.add_rounded,
                    color: hasGstDetails
                        ? cs.onSurface.withValues(alpha: 0.5)
                        : cs.primary,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGstCardSkeleton(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceBright,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.receipt_long_rounded, color: cs.primary, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'GST Details',
                    style: tt.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Manage your business GST info',
                    style: tt.bodyMedium?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAccessCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return TappableCard(
      pressedOpacity: 0.6,
      animationDuration: const Duration(milliseconds: 100),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceBright,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: cs.shadow.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: cs.primary, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: tt.bodyMedium?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: cs.onSurface.withValues(alpha: 0.5),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Text(
      title,
      style: tt.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: cs.onSurface,
      ),
    );
  }

  Widget _buildPersonalInfoSection(BuildContext context, Customer customer) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceBright,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoRow(
            context,
            icon: Icons.person_rounded,
            title: 'First Name',
            value: customer.firstName.isEmpty ? 'Not set' : customer.firstName,
            onEdit: () => _showEditDialog(
              context,
              'First Name',
              customer.firstName,
              (value) => _updateFirstName(value),
            ),
          ),
          _buildDivider(context),
          _buildInfoRow(
            context,
            icon: Icons.person_rounded,
            title: 'Last Name',
            value: customer.lastName.isEmpty ? 'Not set' : customer.lastName,
            onEdit: () => _showEditDialog(
              context,
              'Last Name',
              customer.lastName,
              (value) => _updateLastName(value),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSection(BuildContext context, Customer customer) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceBright,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoRow(
            context,
            icon: Icons.phone_rounded,
            title: 'Phone Number',
            value: customer.phoneNumber,
            onEdit: null,
          ),
          _buildDivider(context),
          _buildInfoRow(
            context,
            icon: Icons.email_rounded,
            title: 'Email',
            value: customer.email.isEmpty ? 'Not linked' : customer.email,
            onEdit: () => _showEmailLinkDialog(customer),
            isAction: customer.email.isEmpty,
            actionLabel: 'Link',
          ),
          _buildDivider(context),
          _buildInfoRow(
            context,
            icon: Icons.calendar_today_rounded,
            title: 'Member Since',
            value: DateTimeUtils.formatShortDateIST(customer.memberSince),
            onEdit: null,
          ),
          if (customer.referralCode.isNotEmpty) ...[
            _buildDivider(context),
            _buildInfoRow(
              context,
              icon: Icons.card_giftcard_rounded,
              title: 'Referral Code',
              value: customer.referralCode,
              onEdit: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ReferralScreen()),
                );
              },
              isAction: true,
              actionLabel: 'Details',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    VoidCallback? onEdit,
    bool isAction = false,
    String? actionLabel,
  }) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(
            icon,
            color: cs.onSurface.withValues(alpha: 0.6),
            size: 22,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: tt.labelMedium?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: tt.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
          if (onEdit != null)
            TextButton(
              onPressed: onEdit,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
              ),
              child: Text(
                isAction ? (actionLabel ?? 'Add') : 'Edit',
                style: tt.labelLarge?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Divider(
      height: 1,
      thickness: 1,
      color: cs.outline.withValues(alpha: 0.1),
      indent: 52,
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return OutlinedButton(
      onPressed: () => _showLogoutDialog(context),
      style: OutlinedButton.styleFrom(
        foregroundColor: cs.error,
        minimumSize: const Size(double.infinity, 52),
        side: BorderSide(color: cs.error.withValues(alpha: 0.5)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.logout_rounded, size: 20),
          const SizedBox(width: 8),
          Text(
            'Logout',
            style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  // Dialog methods
  void _showEditDialog(BuildContext context, String title, String currentValue, Function(String) onSave) {
    showDialog(
      context: context,
      builder: (context) => ProfileEditDialog(
        title: title,
        currentValue: currentValue,
        onSave: onSave,
      ),
    );
  }

  void _showEmailLinkDialog(Customer customer) {
    showDialog(
      context: context,
      builder: (ctx) => EmailLinkDialog(
        currentEmail: customer.email.isEmpty ? null : customer.email,
        onSuccess: () {
          ref.invalidate(customerProvider);
          SnackBars.success(context, 'Email linked successfully');
        },
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) async {
    final cs = Theme.of(context).colorScheme;

    final shouldLogout = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Logout',
              style: TextStyle(color: cs.error),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout == true && mounted) {
      await ref.read(apiProvider).value!.signOut();
    }
  }

  // Update methods
  Future<void> _updateFirstName(String value) async {
    try {
      final api = ref.read(apiProvider).value!;
      await customer_api.updateCustomerProfile(
        api,
        firstName: value.trim(),
      );
      ref.invalidate(customerProvider);
      if (mounted) {
        SnackBars.success(context, 'First name updated successfully');
      }
    } catch (e) {
      if (mounted) {
        SnackBars.error(context, 'Failed to update first name: $e');
      }
    }
  }

  Future<void> _updateLastName(String value) async {
    try {
      final api = ref.read(apiProvider).value!;
      await customer_api.updateCustomerProfile(
        api,
        lastName: value.trim(),
      );
      ref.invalidate(customerProvider);
      if (mounted) {
        SnackBars.success(context, 'Last name updated successfully');
      }
    } catch (e) {
      if (mounted) {
        SnackBars.error(context, 'Failed to update last name: $e');
      }
    }
  }
}
