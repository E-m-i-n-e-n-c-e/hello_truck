import 'package:flutter/material.dart';
import 'package:hello_truck_app/screens/onboarding/controllers/onboarding_controller.dart';
import 'package:hello_truck_app/screens/onboarding/widgets/onboarding_components.dart';

class PersonalInfoStep extends StatelessWidget {
  final OnboardingController controller;
  final VoidCallback onNext;

  const PersonalInfoStep({
    super.key,
    required this.controller,
    required this.onNext,
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
            icon: Icons.person_outline_rounded,
          ),

          const SizedBox(height: 40),

          // Title
          OnboardingStepTitle(
            controller: controller,
            title: 'Let\'s get to know you',
          ),

          const SizedBox(height: 16),

          OnboardingStepDescription(
            controller: controller,
            description: 'Tell us your name so we can personalize your Hello Truck experience.',
          ),

          const SizedBox(height: 56),

          // First Name
          OnboardingTextField(
            controller: controller,
            textController: controller.firstNameController,
            focusNode: controller.firstNameFocus,
            label: 'First Name',
            hint: 'Enter your first name',
            icon: Icons.person_rounded,
            isRequired: true,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'First name is required';
              }
              return null;
            },
            onSubmitted: (_) => controller.lastNameFocus.requestFocus(),
          ),

          const SizedBox(height: 24),

          // Last Name
          OnboardingTextField(
            controller: controller,
            textController: controller.lastNameController,
            focusNode: controller.lastNameFocus,
            label: 'Last Name',
            hint: 'Enter your last name (optional)',
            icon: Icons.person_outline_rounded,
            onSubmitted: (_) => onNext(),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
