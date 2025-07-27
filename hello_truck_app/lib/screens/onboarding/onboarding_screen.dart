import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_truck_app/providers/auth_providers.dart';
import 'package:hello_truck_app/utils/api/customer_api.dart' as customer_api;
import 'package:hello_truck_app/widgets/snackbars.dart';
import 'package:hello_truck_app/screens/onboarding/controllers/onboarding_controller.dart';
import 'package:hello_truck_app/screens/onboarding/widgets/onboarding_header.dart';
import 'package:hello_truck_app/screens/onboarding/widgets/onboarding_bottom_section.dart';
import 'package:hello_truck_app/screens/onboarding/steps/personal_info_step.dart';
import 'package:hello_truck_app/screens/onboarding/steps/email_step.dart';
import 'package:hello_truck_app/screens/onboarding/steps/business_details_step.dart';
import 'package:hello_truck_app/screens/onboarding/steps/review_step.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with TickerProviderStateMixin {
  late OnboardingController _controller;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controller = OnboardingController(vsync: this);

    // Set up state change callback to trigger rebuilds
    _controller.setStateChangeCallback(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _nextStep() async {
    if (await _validateCurrentStep()) {
      if (_controller.currentStep < _controller.getTotalSteps() - 1) {
        if (mounted) {
          FocusScope.of(context).unfocus(); // Dismiss keyboard
        }
        _controller.nextStep();
        _controller.pageController.nextPage(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutCubic,
        );
      }
    }
  }

  void _previousStep() {
    if (_controller.currentStep > 0) {
      if (mounted) {
        FocusScope.of(context).unfocus(); // Dismiss keyboard
      }
      _controller.previousStep();
      _controller.pageController.previousPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  Future<bool> _validateCurrentStep() async {
    switch (_controller.currentStep) {
      case 0: // Personal Info
        if (!_controller.validatePersonalInfo()) {
          _showError('Please enter your first name');
          return false;
        }
        return true;

      case 1: // Email
        if (!_controller.validateEmail()) {
          _showError('Please enter a valid email address');
          return false;
        }
        return true;

      case 2: // Business Details
        final error = _controller.validateBusinessDetails();
        if (error != null) {
          _showError(error);
          return false;
        }
        return true;

      default:
        return true;
    }
  }

  Future<void> _submitForm() async {
    if (!await _validateCurrentStep()) return;

    _controller.setLoading(true);
    try {
      final api = await ref.read(apiProvider.future);

      await customer_api.createCustomerProfile(
        api,
        firstName: _controller.firstNameController.text.trim(),
        lastName: _controller.lastNameController.text.trim().isEmpty
            ? null
            : _controller.lastNameController.text.trim(),
        googleIdToken: _controller.googleIdToken,
        referralCode: _controller.referralController.text.trim().isEmpty
            ? null
            : _controller.referralController.text.trim(),
        gstDetails: _controller.getGstDetails(),
      );

      if (mounted) {
        // Refresh tokens to update auth state
        ref.read(authClientProvider).refreshTokens();
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to create profile: $e');
        _controller.setLoading(false);
      }
    }
  }

  void _showError(String message) {
    SnackBars.error(context, message);
  }

  void _showSuccess(String message) {
    SnackBars.success(context, message);
  }

  List<Widget> _getSteps() {
    final steps = <Widget>[
      // Step 0: Personal Info
      PersonalInfoStep(
        controller: _controller,
        onNext: _nextStep,
      ),

      // Step 1: Email
      EmailStep(
        controller: _controller,
        onNext: _nextStep,
        onError: _showError,
        onSuccess: _showSuccess,
      ),

      // Step 2: Business Details
      BusinessDetailsStep(
        controller: _controller,
        onNext: _nextStep,
      ),

      // Step 3: Review
      ReviewStep(
        controller: _controller,
        onSubmit: _submitForm,
      ),
    ];

    return steps;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Header with progress
              OnboardingHeader(controller: _controller),

              // Content
              Expanded(
                child: PageView(
                  controller: _controller.pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: _getSteps().map((step) {
                    return SingleChildScrollView(
                      child: Column(
                        children: [
                          // Step content
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: MediaQuery.of(context).size.height -
                                        MediaQuery.of(context).padding.top -
                                        MediaQuery.of(context).padding.bottom -
                                        180, // Adjust based on header and bottom section height
                            ),
                            child: step,
                          ),
                          // Bottom section with navigation
                          OnboardingBottomSection(
                            controller: _controller,
                            onNext: _nextStep,
                            onPrevious: _previousStep,
                            onSubmit: _submitForm,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
