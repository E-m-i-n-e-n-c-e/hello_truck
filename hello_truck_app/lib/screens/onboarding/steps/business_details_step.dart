import 'package:flutter/material.dart';
import 'package:hello_truck_app/screens/onboarding/controllers/onboarding_controller.dart';
import 'package:hello_truck_app/screens/onboarding/widgets/onboarding_components.dart';

class BusinessDetailsStep extends StatelessWidget {
  final OnboardingController controller;
  final VoidCallback onNext;

  const BusinessDetailsStep({
    super.key,
    required this.controller,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return OnboardingStepContainer(
      controller: controller,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
            const SizedBox(height: 16),

            // Icon
            OnboardingStepIcon(
              controller: controller,
              icon: Icons.business_outlined,
            ),

            const SizedBox(height: 24),

            // Title
            OnboardingStepTitle(
              controller: controller,
              title: 'Business Account',
            ),

            const SizedBox(height: 12),

            OnboardingStepDescription(
              controller: controller,
              description: 'Choose whether you want to use Hello Truck for personal or business purposes.',
            ),

            const SizedBox(height: 24),

          // Business toggle
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.business_center_rounded,
                  color: colorScheme.secondary,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Business Account',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Enable for GST billing and business features',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: controller.isBusiness,
                  onChanged: (value) => controller.toggleBusiness(value),
                  activeThumbColor: colorScheme.secondary,
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Business details (shown when business is enabled)
          if (controller.isBusiness) ...[
            // GST Number
            OnboardingTextField(
              controller: controller,
              textController: controller.gstNumberController,
              focusNode: controller.gstNumberFocus,
              label: 'GST Number',
              hint: 'Enter your GST number',
              icon: Icons.receipt_long_rounded,
              isRequired: true,
              onSubmitted: (_) => controller.companyNameFocus.requestFocus(),
            ),

            const SizedBox(height: 24),

            // Company Name
            OnboardingTextField(
              controller: controller,
              textController: controller.companyNameController,
              focusNode: controller.companyNameFocus,
              label: 'Company Name',
              hint: 'Enter your company name',
              icon: Icons.domain_rounded,
              isRequired: true,
              onSubmitted: (_) => controller.addressFocus.requestFocus(),
            ),

            const SizedBox(height: 24),

            // Business Address
            OnboardingTextField(
              controller: controller,
              textController: controller.addressController,
              focusNode: controller.addressFocus,
              label: 'Business Address',
              hint: 'Enter your business address',
              icon: Icons.location_on_rounded,
              isRequired: true,
              maxLines: 3,
              onSubmitted: (_) => onNext(),
            ),

            const SizedBox(height: 40),
          ],
        ],
      ),
    );
  }
}
