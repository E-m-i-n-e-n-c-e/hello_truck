import 'package:flutter/material.dart';
import 'package:hello_truck_app/screens/onboarding/controllers/onboarding_controller.dart';
import 'package:hello_truck_app/screens/onboarding/widgets/onboarding_components.dart';

class ReviewStep extends StatelessWidget {
  final OnboardingController controller;
  final VoidCallback onSubmit;

  const ReviewStep({
    super.key,
    required this.controller,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return OnboardingStepContainer(
      controller: controller,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 32),

          // Icon
          OnboardingStepIcon(
            controller: controller,
            icon: Icons.check_circle_outline_rounded,
          ),

          const SizedBox(height: 40),

          // Title
          OnboardingStepTitle(
            controller: controller,
            title: 'Review Your Details',
          ),

          const SizedBox(height: 16),

          OnboardingStepDescription(
            controller: controller,
            description: 'Please review your information before completing your profile setup.',
          ),

          const SizedBox(height: 40),

          // Review cards
          _buildReviewCard(
            context,
            title: 'Personal Information',
            icon: Icons.person_rounded,
            children: [
              _buildReviewItem(
                'Name',
                '${controller.firstNameController.text.trim()} ${controller.lastNameController.text.trim()}'.trim(),
              ),
              _buildReviewItem(
                'Email',
                controller.emailController.text.trim(),
              ),
            ],
          ),

          const SizedBox(height: 16),

          if (controller.isBusiness) ...[
            _buildReviewCard(
              context,
              title: 'Business Information',
              icon: Icons.business_rounded,
              children: [
                _buildReviewItem(
                  'Company Name',
                  controller.companyNameController.text.trim(),
                ),
                _buildReviewItem(
                  'GST Number',
                  controller.gstNumberController.text.trim(),
                ),
                _buildReviewItem(
                  'Business Address',
                  controller.addressController.text.trim(),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Address Information
          if (controller.validateAddressStep()) ...[
            _buildReviewCard(
              context,
              title: 'Address Information',
              icon: Icons.location_on_rounded,
              children: [
                _buildReviewItem(
                  'Address',
                  controller.addressLine1Controller.text.trim(),
                ),
                if (controller.landmarkController.text.trim().isNotEmpty)
                  _buildReviewItem(
                    'Landmark',
                    controller.landmarkController.text.trim(),
                  ),
                _buildReviewItem(
                  'City',
                  '${controller.cityController.text.trim()}, ${controller.stateController.text.trim()}',
                ),
                _buildReviewItem(
                  'Pincode',
                  controller.pincodeController.text.trim(),
                ),
                if (controller.phoneNumberController.text.trim().isNotEmpty)
                  _buildReviewItem(
                    'Phone',
                    controller.phoneNumberController.text.trim(),
                  ),
                if (controller.addressLabelController.text.trim().isNotEmpty)
                  _buildReviewItem(
                    'Label',
                    controller.addressLabelController.text.trim(),
                  ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          if (controller.referralController.text.trim().isNotEmpty) ...[
            _buildReviewCard(
              context,
              title: 'Referral',
              icon: Icons.card_giftcard_rounded,
              children: [
                _buildReviewItem(
                  'Referral Code',
                  controller.referralController.text.trim(),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Referral code (optional)
          OnboardingTextField(
            controller: controller,
            textController: controller.referralController,
            focusNode: controller.referralFocus,
            label: 'Referral Code (Optional)',
            hint: 'Enter referral code if you have one',
            icon: Icons.card_giftcard_rounded,
            onSubmitted: (_) => onSubmit(),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildReviewCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: colorScheme.secondary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildReviewItem(String label, String value) {
    return Builder(
      builder: (context) {
        final textTheme = Theme.of(context).textTheme;
        final colorScheme = Theme.of(context).colorScheme;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 100,
                child: Text(
                  label,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  value.isEmpty ? 'Not provided' : value,
                  style: textTheme.bodyMedium?.copyWith(
                    color: value.isEmpty
                        ? colorScheme.onSurface.withValues(alpha: 0.5)
                        : colorScheme.onSurface,
                    fontStyle: value.isEmpty ? FontStyle.italic : null,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
