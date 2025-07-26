import 'package:flutter/material.dart';
import 'package:hello_truck_app/screens/onboarding/controllers/onboarding_controller.dart';

class OnboardingHeader extends StatelessWidget {
  final OnboardingController controller;

  const OnboardingHeader({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final totalSteps = controller.getTotalSteps();

    return AnimatedBuilder(
      animation: controller.fadeAnimation,
      builder: (context, _) {
        return FadeTransition(
          opacity: controller.fadeAnimation,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                // Progress indicator
                Row(
                  children: [
                    for (int i = 0; i < totalSteps; i++) ...[
                      Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: 4,
                          decoration: BoxDecoration(
                            color: i <= controller.currentStep
                                ? colorScheme.secondary
                                : colorScheme.outline.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      if (i < totalSteps - 1) const SizedBox(width: 8),
                    ],
                  ],
                ),
                const SizedBox(height: 16),

                // Step counter
                Text(
                  'Step ${controller.currentStep + 1} of $totalSteps',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
