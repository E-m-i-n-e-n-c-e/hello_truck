import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_truck_app/models/gst_details.dart';
import 'package:hello_truck_app/providers/auth_providers.dart';
import 'package:hello_truck_app/utils/api/customer_api.dart' as customer_api;
import 'package:hello_truck_app/widgets/snackbars.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _referralController = TextEditingController();
  final _gstNumberController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isBusiness = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _referralController.dispose();
    _gstNumberController.dispose();
    _companyNameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final api = await ref.read(apiProvider.future);

      // Add GST details if business account
      GstDetails? gstDetails;
      if (_isBusiness) {
        gstDetails = GstDetails(
          gstNumber: _gstNumberController.text.trim(),
          businessName: _companyNameController.text.trim(),
          businessAddress: _addressController.text.trim(),
        );
      }
      customer_api.createCustomerProfile(
        api,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        referralCode: _referralController.text.trim(),
        gstDetails: _isBusiness ? gstDetails : null,
      );
      ref.read(authClientProvider).refreshTokens();
    } catch (e) {
      if (mounted) {
        SnackBars.error(context, 'Failed to create profile: $e');
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Complete Your Profile',
          style: textTheme.titleLarge?.copyWith(
            color: colorScheme.onSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: colorScheme.secondary,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Please provide your details to continue',
                style: textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha:0.7),
                ),
              ),
              const SizedBox(height: 24),

              // First Name
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: 'First Name',
                  hintText: 'Enter your first name',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'First name is required';
                  }
                  return null;
                },
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              // Last Name
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Last Name (Optional)',
                  hintText: 'Enter your last name',
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              // Email
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'Enter your email address',
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Email is required';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              // Business Account Switch
              SwitchListTile(
                title: const Text('Business Account'),
                subtitle: const Text('Enable for business use'),
                value: _isBusiness,
                onChanged: (value) => setState(() => _isBusiness = value),
              ),
              const SizedBox(height: 16),

              // GST Details Section (Visible only when business account is selected)
              if (_isBusiness) ...[
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Business Details',
                    style: textTheme.titleMedium,
                  ),
                ),
                TextFormField(
                  controller: _gstNumberController,
                  decoration: const InputDecoration(
                    labelText: 'GST Number',
                    hintText: 'Enter your GST number',
                  ),
                  validator: _isBusiness
                      ? (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'GST number is required for business accounts';
                          }
                          if (!RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$').hasMatch(value)) {
                            return 'Please enter a valid GST number';
                          }
                          return null;
                        }
                      : null,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _companyNameController,
                  decoration: const InputDecoration(
                    labelText: 'Company Name',
                    hintText: 'Enter your company name',
                  ),
                  validator: _isBusiness
                      ? (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Company name is required for business accounts';
                          }
                          return null;
                        }
                      : null,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Business Address',
                    hintText: 'Enter your business address',
                  ),
                  validator: _isBusiness
                      ? (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Business address is required for business accounts';
                          }
                          return null;
                        }
                      : null,
                  maxLines: 3,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
              ],

              // Referral Code (Optional)
              TextFormField(
                controller: _referralController,
                decoration: const InputDecoration(
                  labelText: 'Referral Code (Optional)',
                  hintText: 'Enter referral code if you have one',
                ),
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 32),

              // Submit Button
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: colorScheme.secondary,
                  foregroundColor: colorScheme.onSecondary,
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
                    : const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}