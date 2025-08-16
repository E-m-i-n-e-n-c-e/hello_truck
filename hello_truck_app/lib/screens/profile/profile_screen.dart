import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_truck_app/models/customer.dart';
import 'package:hello_truck_app/models/gst_details.dart';
import 'package:hello_truck_app/providers/auth_providers.dart';
import 'package:hello_truck_app/providers/customer_providers.dart';
import 'package:hello_truck_app/api/customer_api.dart' as customer_api;
import 'package:hello_truck_app/api/gst_details_api.dart' as gst_api;
import 'package:hello_truck_app/widgets/snackbars.dart';
import 'package:hello_truck_app/screens/profile/profile_edit_dialogs.dart';
import 'package:hello_truck_app/screens/profile/email_link_dialog.dart';
import 'package:hello_truck_app/screens/profile/gst_details_dialog.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final customer = ref.watch(customerProvider);
    final gstDetails = ref.watch(gstDetailsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Profile',
          style: textTheme.titleLarge?.copyWith(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showGstDetailsDialog(),
        backgroundColor: colorScheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: customer.when(
        data: (customer) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Header
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          ('${customer.firstName.isNotEmpty ? customer.firstName[0] : ''}'
                                  '${customer.lastName.isNotEmpty ? customer.lastName[0] : ''}')
                              .toUpperCase(),
                          style: textTheme.headlineLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${customer.firstName} ${customer.lastName}'.trim(),
                        style: textTheme.headlineMedium?.copyWith(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (customer.email.isNotEmpty)
                        Text(
                          customer.email,
                          style: textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // Profile Info Section
                Text(
                  'Personal Information',
                  style: textTheme.titleLarge?.copyWith(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),

                // Profile Info with Edit Buttons
                _EditableInfoTile(
                  icon: Icons.person_rounded,
                  title: 'First Name',
                  subtitle: customer.firstName.isEmpty ? 'Not set' : customer.firstName,
                  onEdit: () => _showEditDialog(
                    context,
                    'First Name',
                    customer.firstName,
                    (value) => _updateFirstName(value),
                  ),
                ),
                const SizedBox(height: 16),

                _EditableInfoTile(
                  icon: Icons.person_rounded,
                  title: 'Last Name',
                  subtitle: customer.lastName.isEmpty ? 'Not set' : customer.lastName,
                  onEdit: () => _showEditDialog(
                    context,
                    'Last Name',
                    customer.lastName,
                    (value) => _updateLastName(value),
                  ),
                ),
                const SizedBox(height: 16),

                _EditableInfoTile(
                  icon: Icons.email_rounded,
                  title: 'Email',
                  subtitle: customer.email.isEmpty ? 'Not linked' : customer.email,
                  onEdit: () => _showEmailLinkDialog(customer),
                  isLinked: customer.email.isNotEmpty,
                ),
                const SizedBox(height: 16),

                _EditableInfoTile(
                  icon: Icons.phone_rounded,
                  title: 'Phone Number',
                  subtitle: customer.phoneNumber.isEmpty ? 'Not set' : customer.phoneNumber,
                  onEdit: null, // Phone number cannot be edited
                ),

                // GST Details Section
                const SizedBox(height: 40),
                Text(
                  'GST Details',
                  style: textTheme.titleLarge?.copyWith(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),

                gstDetails.when(
                  data: (details) {
                                         if (details.isEmpty) {
                       return Container(
                         width: double.infinity,
                         padding: const EdgeInsets.all(32),
                         decoration: BoxDecoration(
                           color: Colors.grey.shade50,
                           borderRadius: BorderRadius.circular(12),
                         ),
                         child: Column(
                           children: [
                             Icon(
                               Icons.receipt_long_outlined,
                               size: 48,
                               color: Colors.grey.shade400,
                             ),
                             const SizedBox(height: 16),
                             Text(
                               'No GST details added yet',
                               style: textTheme.titleMedium?.copyWith(
                                 color: Colors.black87,
                                 fontWeight: FontWeight.w500,
                               ),
                             ),
                             const SizedBox(height: 8),
                             Text(
                               'Add your GST details to get tax invoices',
                               style: textTheme.bodyMedium?.copyWith(
                                 color: Colors.grey.shade600,
                               ),
                               textAlign: TextAlign.center,
                             ),
                           ],
                         ),
                       );
                     }

                    return Column(
                      children: details.map((detail) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _GstDetailCard(
                            gstDetail: detail,
                            onEdit: () => _showGstDetailsDialog(existingDetails: detail),
                            onDeactivate: () => _deactivateGstDetails(detail.id ?? ''),
                          ),
                        );
                      }).toList(),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, _) => Container(
                     width: double.infinity,
                     padding: const EdgeInsets.all(20),
                     decoration: BoxDecoration(
                       color: Colors.red.shade50,
                       borderRadius: BorderRadius.circular(12),
                     ),
                     child: Column(
                       children: [
                         Icon(
                           Icons.error_outline,
                           size: 32,
                           color: Colors.red.shade400,
                         ),
                         const SizedBox(height: 12),
                         Text(
                           'Error loading GST details',
                           style: textTheme.titleMedium?.copyWith(
                             color: Colors.red.shade700,
                             fontWeight: FontWeight.w500,
                           ),
                         ),
                         const SizedBox(height: 8),
                         TextButton(
                           onPressed: () => ref.invalidate(gstDetailsProvider),
                           child: const Text('Try Again'),
                         ),
                       ],
                     ),
                   ),
                ),

                // Logout Button
                const SizedBox(height: 40),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.red.shade200,
                      width: 1,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () async {
                        final shouldLogout = await showDialog<bool>(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => AlertDialog(
                            title: Text(
                              'Logout',
                              style: textTheme.titleLarge?.copyWith(
                                color: Colors.black87,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            content: Text(
                              'Are you sure you want to logout?',
                              style: textTheme.bodyMedium?.copyWith(
                                color: Colors.grey.shade600,
                              ),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text(
                                  'CANCEL',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: Text(
                                  'LOGOUT',
                                  style: TextStyle(color: Colors.red.shade600),
                                ),
                              ),
                            ],
                          ),
                        );

                        if (shouldLogout == true && mounted) {
                          await ref.read(apiProvider).value!.signOut();
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              Icons.logout,
                              color: Colors.red.shade600,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Logout',
                              style: textTheme.titleMedium?.copyWith(
                                color: Colors.red.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Colors.red.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading profile',
                  style: textTheme.titleMedium?.copyWith(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => ref.invalidate(customerProvider),
                  child: const Text('Try Again'),
                ),
              ],
            ),
          );
        },
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

  void _showGstDetailsDialog({GstDetails? existingDetails}) {
    showDialog(
      context: context,
      builder: (ctx) => GstDetailsDialog(
        existingDetails: existingDetails,
        onSuccess: () {
          ref.invalidate(gstDetailsProvider);
          SnackBars.success(context, 'GST details ${existingDetails == null ? 'added' : 'updated'} successfully');
        },
      ),
    );
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

  Future<void> _deactivateGstDetails(String id) async {
    final shouldDeactivate = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Deactivate GST Details'),
        content: const Text('Are you sure you want to deactivate these GST details?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'DEACTIVATE',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (shouldDeactivate == true) {
      try {
        final api = ref.read(apiProvider).value!;
        await gst_api.deactivateGstDetails(api, id);
        ref.invalidate(gstDetailsProvider);
        if (mounted) {
          SnackBars.success(context, 'GST details deactivated successfully');
        }
      } catch (e) {
        if (mounted) {
          SnackBars.error(context, 'Failed to deactivate GST details: $e');
        }
      }
    }
  }
}

class _EditableInfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onEdit;
  final bool isLinked;

  const _EditableInfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onEdit,
    this.isLinked = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: colorScheme.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: textTheme.titleSmall?.copyWith(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (isLinked) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.verified_rounded,
                        size: 16,
                        color: Colors.green,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: textTheme.titleMedium?.copyWith(
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (onEdit != null)
            IconButton(
              onPressed: onEdit,
              icon: Icon(
                Icons.edit_rounded,
                color: colorScheme.primary,
                size: 20,
              ),
            ),
        ],
      ),
    );
  }
}

class _GstDetailCard extends StatelessWidget {
  final GstDetails gstDetail;
  final VoidCallback onEdit;
  final VoidCallback onDeactivate;

  const _GstDetailCard({
    required this.gstDetail,
    required this.onEdit,
    required this.onDeactivate,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  gstDetail.businessName,
                  style: textTheme.titleMedium?.copyWith(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'deactivate',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Text('Deactivate', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'edit') {
                    onEdit();
                  } else if (value == 'deactivate') {
                    onDeactivate();
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'GST Number: ${gstDetail.gstNumber}',
            style: textTheme.bodyMedium?.copyWith(
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            gstDetail.businessAddress,
            style: textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}