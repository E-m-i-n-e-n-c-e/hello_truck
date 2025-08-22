import 'package:flutter/material.dart';
import 'package:hello_truck_app/screens/onboarding/controllers/onboarding_controller.dart';

class OnboardingBottomSection extends StatelessWidget {
  final OnboardingController controller;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;
  final VoidCallback? onSubmit;
  final String? nextButtonText;
  final bool showBackButton;

  const OnboardingBottomSection({
    super.key,
    required this.controller,
    this.onNext,
    this.onPrevious,
    this.onSubmit,
    this.nextButtonText,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLastStep = controller.currentStep == controller.getTotalSteps() - 1;
    final isFirstStep = controller.currentStep == 0;
    final canProceed = isLastStep
        ? controller.canSubmitProfile()
        : controller.canProceedFromCurrentStep();

    return AnimatedBuilder(
      animation: controller.fadeAnimation,
      builder: (context, _) {
        return FadeTransition(
          opacity: controller.fadeAnimation,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Back button
                  if (showBackButton && !isFirstStep)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: controller.isLoading ? null : onPrevious,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(
                            color: colorScheme.outline.withValues(alpha: 0.5),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.arrow_back_ios_rounded,
                              size: 18,
                              color: colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Back',
                              style: TextStyle(
                                color: colorScheme.onSurface.withValues(alpha: 0.7),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  if (showBackButton && !isFirstStep) const SizedBox(width: 16),

                  // Next/Submit button
                  Expanded(
                    flex: showBackButton && !isFirstStep ? 1 : 2,
                    child: ElevatedButton(
                      onPressed: (controller.isLoading || !canProceed)
                          ? null
                          : (isLastStep ? onSubmit : onNext),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: colorScheme.secondary,
                        foregroundColor: colorScheme.onSecondary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: controller.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  isLastStep
                                      ? 'Complete Profile'
                                      : (nextButtonText ?? 'Continue'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  isLastStep
                                      ? Icons.check_rounded
                                      : Icons.arrow_forward_ios_rounded,
                                  size: 18,
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
