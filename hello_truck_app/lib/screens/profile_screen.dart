import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_truck_app/models/customer.dart';
import 'package:hello_truck_app/models/gst_details.dart';
import 'package:hello_truck_app/providers/auth_providers.dart';
import 'package:hello_truck_app/utils/api/customer_api.dart' as customer_api;
import 'package:hello_truck_app/utils/api/gst_details_api.dart' as gst_api;
import 'package:hello_truck_app/widgets/snackbars.dart';

final customerProvider = FutureProvider.autoDispose<Customer>((ref) async {
  final api = await ref.watch(apiProvider.future);
  return customer_api.getCustomerProfile(api);
});

final gstDetailsProvider = FutureProvider.autoDispose<List<GstDetails>>((ref) async {
  final api = await ref.watch(apiProvider.future);
  return gst_api.getGstDetails(api);
});

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isEditing = false;
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _emailController = TextEditingController();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _initializeControllers(Customer customer) {
    _firstNameController.text = customer.firstName;
    _lastNameController.text = customer.lastName;
    _emailController.text = customer.email;
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiProvider).value!;
      await customer_api.updateCustomerProfile(
        api,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
      );

      if (mounted) {
        setState(() => _isEditing = false);
        SnackBars.success(context, 'Profile updated successfully');
        // Refresh profile data
        ref.invalidate(customerProvider);
      }
    } catch (e) {
      if (mounted) {
        SnackBars.error(context, 'Failed to update profile: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showReactivateGstDetailsDialog({required String gstNumber}) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('GST Details Already Exists'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'We found an existing GST registration with this number that is currently inactive.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            const Text(
              'Would you like to reactivate these GST details?',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'GST Number: $gstNumber',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reactivate'),
          ),
        ],
      ),
    );

    if (result == true) {
      final api = ref.read(apiProvider).value!;
      try {
        await gst_api.reactivateGstDetails(api, gstNumber);
        ref.invalidate(gstDetailsProvider);
        if (mounted) {
          SnackBars.success(context, 'GST details reactivated successfully');
        }
      } catch (e) {
        if (mounted) {
          SnackBars.error(context, 'Failed to reactivate GST details: $e');
        }
      }
    }
  }

  Future<void> _showGstDetailsDialog({GstDetails? existingDetails}) async {
    final gstNumberController = TextEditingController(text: existingDetails?.gstNumber ?? '');
    final businessNameController = TextEditingController(text: existingDetails?.businessName ?? '');
    final businessAddressController = TextEditingController(text: existingDetails?.businessAddress ?? '');
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;
    const kDialogCancel = null;
    const kDialogSuccess = 'Success';

    final result = await showDialog<String?>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(existingDetails == null ? 'Add GST Details' : 'Edit GST Details'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: gstNumberController,
                    decoration: const InputDecoration(
                      labelText: 'GST Number',
                      hintText: 'Enter GST number',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'GST number is required';
                      }
                      if (!RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$')
                          .hasMatch(value)) {
                        return 'Invalid GST number format';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: businessNameController,
                    decoration: const InputDecoration(
                      labelText: 'Business Name',
                      hintText: 'Enter business name',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Business name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: businessAddressController,
                    decoration: const InputDecoration(
                      labelText: 'Business Address',
                      hintText: 'Enter business address',
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Business address is required';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, kDialogCancel),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;

                      setState(() => isLoading = true);
                      try {
                        final api = ref.read(apiProvider).value!;

                        if (existingDetails != null) {
                          await gst_api.updateGstDetails(
                            api,
                            id: existingDetails.id ?? '',
                            gstNumber: gstNumberController.text.trim(),
                            businessName: businessNameController.text.trim(),
                            businessAddress: businessAddressController.text.trim(),
                          );
                        } else {
                          await gst_api.addGstDetails(
                            api,
                            gstNumber: gstNumberController.text.trim(),
                            businessName: businessNameController.text.trim(),
                            businessAddress: businessAddressController.text.trim(),
                          );
                        }

                        if (context.mounted) {
                          Navigator.pop(context, kDialogSuccess);
                        }
                      } catch (e) {
                        if (context.mounted) {
                          if(e.toString().contains('GST number already exists but is inactive. Please reactivate it.')) {
                            // Cancel the dialog and show the reactivate dialog
                            Navigator.pop(context, kDialogCancel);
                            _showReactivateGstDetailsDialog(gstNumber: gstNumberController.text.trim());
                          }
                          else{
                            Navigator.pop(context, e.toString());
                          }
                        }
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(existingDetails == null ? 'ADD' : 'UPDATE'),
            ),
          ],
        ),
      ),
    );

    if(result == kDialogCancel) return;

    if (result == kDialogSuccess) {
      if(mounted){
        SnackBars.success(context, 'GST details ${existingDetails == null ? 'added' : 'updated'} successfully');
      }
      ref.invalidate(gstDetailsProvider);
    }
    else if (mounted) {
      SnackBars.error(context, 'Failed to ${existingDetails == null ? 'add' : 'update'} GST details: $result');
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final customer = ref.watch(customerProvider);
    final gstDetails = ref.watch(gstDetailsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profile',
          style: textTheme.titleLarge?.copyWith(
            color: colorScheme.onPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: colorScheme.primary,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            )
          else
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => setState(() => _isEditing = false),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showGstDetailsDialog(),
        child: const Icon(Icons.add),
      ),
      body: customer.when(
        data: (customer) {
          if (!_isEditing) {
            _initializeControllers(customer);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Header
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: colorScheme.primary.withValues(alpha:0.1),
                          child: Text(
                            ('${customer.firstName.isNotEmpty ? customer.firstName[0] : ''}'
                                    '${customer.lastName.isNotEmpty ? customer.lastName[0] : ''}')
                                .toUpperCase(),
                            style: textTheme.headlineMedium?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (!_isEditing) ...[
                          Text(
                            '${customer.firstName} ${customer.lastName}'.trim(),
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (customer.email.isNotEmpty)
                            Text(
                              customer.email,
                              style: textTheme.titleMedium?.copyWith(
                                color: colorScheme.onSurface.withValues(alpha:0.7),
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  if (_isEditing) ...[
                    // Edit Form
                    TextFormField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(
                        labelText: 'First Name',
                        hintText: 'Enter your first name',
                      ),
                      enabled: _isEditing && !_isLoading,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'First name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(
                        labelText: 'Last Name',
                        hintText: 'Enter your last name',
                      ),
                      enabled: _isEditing && !_isLoading,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'Enter your email address',
                      ),
                      enabled: _isEditing && !_isLoading,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return null;
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    ElevatedButton(
                      onPressed: _isLoading ? null : _updateProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Save Changes'),
                    ),
                  ] else ...[
                    // Profile Info
                    _InfoTile(
                      icon: Icons.phone,
                      title: 'Phone Number',
                      subtitle: customer.phoneNumber.isEmpty ? 'Not set' : customer.phoneNumber,
                    ),
                    const SizedBox(height: 32),

                    // GST Details Section
                    Text(
                      'GST Details',
                      style: textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),

                    gstDetails.when(
                      data: (details) {
                        if (details.isEmpty) {
                          return Center(
                            child: Text(
                              'No GST details added yet',
                              style: textTheme.bodyLarge?.copyWith(
                                color: colorScheme.onSurface.withValues(alpha:0.7),
                              ),
                            ),
                          );
                        }

                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: details.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final detail = details[index];
                            return _GstDetailCard(
                              gstDetail: detail,
                              onEdit: () => _showGstDetailsDialog(existingDetails: detail),
                              onDeactivate: () => _deactivateGstDetails(detail.id ?? ''),
                            );
                          },
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (error, _) => Center(
                        child: Text(
                          'Error loading GST details: $error',
                          style: textTheme.bodyLarge?.copyWith(
                            color: colorScheme.error,
                          ),
                        ),
                      ),
                    ),
                  ],

                  // Logout Button
                  if (!_isEditing) ...[
                    const SizedBox(height: 32),
                    OutlinedButton(
                      onPressed: () async {
                        final shouldLogout = await showDialog<bool>(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => AlertDialog(
                            title: const Text('Logout'),
                            content: const Text('Are you sure you want to logout?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('CANCEL'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: Text(
                                  'LOGOUT',
                                  style: TextStyle(color: colorScheme.error),
                                ),
                              ),
                            ],
                          ),
                        );

                        if (shouldLogout == true && mounted) {
                          await ref.read(apiProvider).value!.signOut();
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorScheme.error,
                        minimumSize: const Size(double.infinity, 50),
                        side: BorderSide(color: colorScheme.error),
                      ),
                      child: const Text('Logout'),
                    ),
                  ],
                ],
              ),
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
                  color: colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading profile: $error',
                  style: textTheme.titleMedium?.copyWith(
                    color: colorScheme.error,
                  ),
                  textAlign: TextAlign.center,
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
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha:0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha:0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: colorScheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.titleSmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha:0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  gstDetail.businessName,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'deactivate',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, color: Colors.red),
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
              style: textTheme.bodyLarge,
            ),
            const SizedBox(height: 4),
            Text(
              gstDetail.businessAddress,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha:0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}