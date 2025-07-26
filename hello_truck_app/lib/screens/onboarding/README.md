# Customer Onboarding Module

This directory contains a well-organized onboarding flow for customers split into logical components for better maintainability and code reuse.

## Structure

```
onboarding/
├── onboarding.dart                    # Main export file
├── onboarding_screen.dart            # Main onboarding screen orchestrator
├── controllers/
│   └── onboarding_controller.dart    # State management and business logic
├── widgets/
│   ├── onboarding_header.dart        # Header with progress indicator
│   ├── onboarding_bottom_section.dart # Bottom action buttons
│   └── onboarding_components.dart    # Shared reusable components
└── steps/
    ├── personal_info_step.dart       # Personal information step
    ├── email_step.dart               # Email input step
    ├── business_details_step.dart    # Business account details (conditional)
    └── review_step.dart              # Review and submit step
```

## Key Features

- **Modular Architecture**: Each step is a separate component for easy maintenance
- **Shared Controller**: Centralized state management with OnboardingController
- **Reusable Components**: Common UI elements like icons, titles, and text fields
- **Enhanced Animations**: Smooth transitions and micro-interactions
- **Modern UI/UX**: Material 3 design with improved visual hierarchy
- **Conditional Flow**: Business details step only shown when business account is enabled
- **Form Validation**: Step-by-step validation with clear error messages

## Onboarding Flow

1. **Personal Information**: First name (required), last name (optional)
2. **Email**: Email address (required, validated)
3. **Business Details** (conditional):
   - Business account toggle
   - GST number, company name, business address (if business account)
4. **Review**: Review all entered information and optional referral code

## Usage

```dart
import 'package:hello_truck_app/screens/onboarding/onboarding.dart';

// Use OnboardingScreen in your navigation
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const OnboardingScreen()),
);
```

## Integration

The onboarding screen integrates with:
- `customer_api.dart` for profile creation
- `auth_providers.dart` for authentication state management
- `models/gst_details.dart` for business account data
- `widgets/snackbars.dart` for error messaging

## Benefits

1. **Maintainability**: Easier to modify individual steps without affecting others
2. **Reusability**: Components can be reused across different parts of the app
3. **Testability**: Each component can be tested in isolation
4. **Performance**: Better tree shaking and smaller bundle sizes
5. **Scalability**: Easy to add new steps or modify existing ones
6. **UX**: Smooth animations and clear progress indication
