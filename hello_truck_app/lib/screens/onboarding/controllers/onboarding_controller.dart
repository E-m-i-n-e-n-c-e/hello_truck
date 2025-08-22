import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hello_truck_app/models/gst_details.dart';
import 'package:hello_truck_app/models/saved_address.dart';

class OnboardingController {
  // Page and Animation Controllers
  final PageController pageController = PageController();
  late AnimationController _animationController;
  late AnimationController _slideAnimationController;
  late AnimationController _scaleAnimationController;
  late Animation<double> fadeAnimation;
  late Animation<Offset> slideAnimation;
  late Animation<double> scaleAnimation;

  // Text Controllers
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final referralController = TextEditingController();
  final gstNumberController = TextEditingController();
  final companyNameController = TextEditingController();
  final addressController = TextEditingController();

  // New Address Controllers for simplified structure
  final addressNameController = TextEditingController();
  final formattedAddressController = TextEditingController();
  final addressDetailsController = TextEditingController();
  final contactNameController = TextEditingController();
  final contactPhoneController = TextEditingController();
  final noteToDriverController = TextEditingController();

  // Focus Nodes
  final firstNameFocus = FocusNode();
  final lastNameFocus = FocusNode();
  final emailFocus = FocusNode();
  final referralFocus = FocusNode();
  final gstNumberFocus = FocusNode();
  final companyNameFocus = FocusNode();
  final addressFocus = FocusNode();

  // New Address Focus Nodes
  final addressNameFocus = FocusNode();
  final addressDetailsFocus = FocusNode();
  final contactNameFocus = FocusNode();
  final contactPhoneFocus = FocusNode();
  final noteToDriverFocus = FocusNode();

  // State Variables
  int _currentStep = 0;
  final int totalSteps = 5; // Personal Info, Email, Business Details (optional), Address, Review
  bool _isLoading = false;
  bool _isBusiness = false;
  bool _isAddressSkipped = false;
  String? _googleIdToken;
  String? _userEmail;

  // Address Map Step State
  double? _selectedLatitude;
  double? _selectedLongitude;

  // State change notifiers
  VoidCallback? _onStateChanged;

  // Getters
  int get currentStep => _currentStep;
  bool get isLoading => _isLoading;
  bool get isBusiness => _isBusiness;
  bool get isAddressSkipped => _isAddressSkipped;
  String? get googleIdToken => _googleIdToken;
  String? get userEmail => _userEmail;
  double? get selectedLatitude => _selectedLatitude;
  double? get selectedLongitude => _selectedLongitude;

  OnboardingController({required TickerProvider vsync}) {
    _initializeAnimations(vsync);
    // Add listeners to notify UI reactively on field edits
    for (final c in [
      firstNameController,
      lastNameController,
      emailController,
      referralController,
      gstNumberController,
      companyNameController,
      addressController,
      addressNameController,
      formattedAddressController,
      addressDetailsController,
      contactNameController,
      contactPhoneController,
      noteToDriverController,
    ]) {
      c.addListener(_notifyStateChange);
    }
  }

  void setStateChangeCallback(VoidCallback callback) {
    _onStateChanged = callback;
  }

  void _notifyStateChange() {
    _onStateChanged?.call();
  }

  void _initializeAnimations(TickerProvider vsync) {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600), // Reduced from 1000ms
      vsync: vsync,
    );

    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400), // Reduced from 800ms
      vsync: vsync,
    );

    _scaleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300), // Reduced from 600ms
      vsync: vsync,
    );

    fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut), // Simpler curve
    );

    slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2), // Reduced from 0.3
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideAnimationController,
      curve: Curves.easeOut, // Simpler curve
    ));

    scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate( // Reduced from 0.8
      CurvedAnimation(parent: _scaleAnimationController, curve: Curves.easeOut), // Simpler curve
    );

    startAnimations();
  }

 void startAnimations() {
    // Start animations sequentially with slight delays to reduce load
    _animationController.forward();

    // Start slide animation with a small delay
    Future.delayed(const Duration(milliseconds: 100), () {
      try {
        _slideAnimationController.forward();
      } catch (e) {
        // Controller might be disposed, ignore
      }
    });

    // Start scale animation with a larger delay
    Future.delayed(const Duration(milliseconds: 200), () {
      try {
        _scaleAnimationController.forward();
      } catch (e) {
        // Controller might be disposed, ignore
      }
    });
  }

  void resetAnimations() {
    _animationController.reset();
    _slideAnimationController.reset();
    _scaleAnimationController.reset();
    startAnimations();
  }

  void shake() {
    _scaleAnimationController.reset();
    _scaleAnimationController.forward();
  }

  // Navigation
  void nextStep() {
    if (_currentStep < totalSteps - 1) {
      _currentStep++;
      _notifyStateChange();
    }
  }

  void previousStep() {
    if (_currentStep > 0) {
      _currentStep--;
      _notifyStateChange();
    }
  }

  void setCurrentStep(int step) {
    _currentStep = step;
    _notifyStateChange();
  }

  // Business toggle
  void toggleBusiness(bool value) {
    _isBusiness = value;
    _notifyStateChange();
  }

  // Address skip toggle
  void setAddressSkipped(bool value) {
    _isAddressSkipped = value;
    _notifyStateChange();
  }

  // Loading state
  void setLoading(bool loading) {
    _isLoading = loading;
    _notifyStateChange();
  }

  // Validation
  bool validatePersonalInfo() {
    return firstNameController.text.trim().isNotEmpty;
  }

  bool validateEmail() {
    // Email step is optional - user can proceed with or without Google verification
    return true;
  }

  String? validateBusinessDetails() {
    if (!_isBusiness) return null;

    final gstNumber = gstNumberController.text.trim();
    final companyName = companyNameController.text.trim();
    final address = addressController.text.trim();

    if (gstNumber.isEmpty || companyName.isEmpty || address.isEmpty) {
      return 'Please fill all the required fields';
    }

    // Validate GST number format
    if (!RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$').hasMatch(gstNumber)) {
      return 'Please enter a valid GST number';
    }

    return null;
  }

  // Get GST details
  GstDetails? getGstDetails() {
    if (!_isBusiness) return null;

    return GstDetails(
      gstNumber: gstNumberController.text.trim(),
      businessName: companyNameController.text.trim(),
      businessAddress: addressController.text.trim(),
    );
  }

  // Address step methods
  void updateSelectedLocation(double latitude, double longitude) {
    _selectedLatitude = latitude;
    _selectedLongitude = longitude;
    _notifyStateChange();
  }

  void updateFormattedAddress(String address) {
    formattedAddressController.text = address;
    _notifyStateChange();
  }

  String? validateAddressStep() {
    if (_isAddressSkipped) {
      return null;
    }
    if (addressNameController.text.trim().isEmpty) {
      return 'Address Name is required';
    }
    if (formattedAddressController.text.trim().isEmpty) {
      return 'Formatted Address is required';
    }
    if (_selectedLatitude == null || _selectedLongitude == null) {
      return 'Location is required';
    }
    if (contactNameController.text.trim().isEmpty) {
      return 'Contact Name is required';
    }
    if (contactPhoneController.text.trim().isEmpty) {
      return 'Contact Phone is required';
    }
    if(!RegExp(r'^[0-9]{10}$').hasMatch(contactPhoneController.text.trim())) {
      return 'Invalid phone number';
    }
    return null;
  }

  // Get saved address object for profile creation
  SavedAddress? getSavedAddressForProfile() {
    if (_isAddressSkipped) return null;
    if (validateAddressStep() != null) return null;

    return SavedAddress(
      id: '', // Will be set by backend
      name: addressNameController.text.trim(),
      address: Address(
        formattedAddress: formattedAddressController.text.trim(),
        addressDetails: addressDetailsController.text.trim().isNotEmpty ? addressDetailsController.text.trim() : null,
        latitude: _selectedLatitude!,
        longitude: _selectedLongitude!,
      ),
      contactName: contactNameController.text.trim(),
      contactPhone: contactPhoneController.text.trim(),
      noteToDriver: noteToDriverController.text.trim(),
      isDefault: true,
      createdAt: DateTime.now(), // Placeholder, will be set by backend
      updatedAt: DateTime.now(), // Placeholder, will be set by backend
    );
  }

  // Reactive readiness helpers for enabling/disabling buttons
  bool hasRequiredPersonalInfo() {
    return firstNameController.text.trim().isNotEmpty;
  }

  bool hasRequiredBusinessDetails() {
    if (!_isBusiness) return true;
    return gstNumberController.text.trim().isNotEmpty &&
        companyNameController.text.trim().isNotEmpty &&
        addressController.text.trim().isNotEmpty;
  }

  bool hasRequiredAddress() {
    if (_isAddressSkipped) return true;
    final phone = contactPhoneController.text.trim();
    final isPhone10Digits = RegExp(r'^[0-9]{10}$').hasMatch(phone);
    return addressNameController.text.trim().isNotEmpty &&
        formattedAddressController.text.trim().isNotEmpty &&
        _selectedLatitude != null &&
        _selectedLongitude != null &&
        contactNameController.text.trim().isNotEmpty &&
        isPhone10Digits;
  }

  bool canProceedFromCurrentStep() {
    switch (_currentStep) {
      case 0:
        return hasRequiredPersonalInfo();
      case 1:
        return true; // Email step optional
      case 2:
        return hasRequiredBusinessDetails();
      case 3:
        return hasRequiredAddress();
      case 4:
        return canSubmitProfile();
      default:
        return false;
    }
  }

  bool canSubmitProfile() {
    return hasRequiredPersonalInfo() && hasRequiredBusinessDetails() && hasRequiredAddress();
  }

  // Get total steps - always 5 steps: Personal, Email, Business, Address, Review
  int getTotalSteps() {
    return 5; // Personal, Email, Business, Address, Review
  }

  // Google OAuth
  Future<void> linkEmailWithGoogle({
    required Function(String) onError,
    required Function(String) onSuccess,
  }) async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: '691159300275-37gn4bpd7jrkld0cmot36vl181s3tsf3.apps.googleusercontent.com',
      );

      await googleSignIn.signOut();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      _googleIdToken = googleAuth.idToken;
      _userEmail = googleUser.email;
      emailController.text = _userEmail ?? '';

      onSuccess('Email verified with Google!');
      _scaleAnimationController.reset();
      _scaleAnimationController.forward();
      _notifyStateChange();
    } catch (e) {
      onError('Failed to sign in with Google: $e');
    }
  }

  void dispose() {
    pageController.dispose();
    _animationController.dispose();
    _slideAnimationController.dispose();
    _scaleAnimationController.dispose();

    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    referralController.dispose();
    gstNumberController.dispose();
    companyNameController.dispose();
    addressController.dispose();

    // New address controllers
    addressNameController.dispose();
    formattedAddressController.dispose();
    addressDetailsController.dispose();
    contactNameController.dispose();
    contactPhoneController.dispose();
    noteToDriverController.dispose();

    firstNameFocus.dispose();
    lastNameFocus.dispose();
    emailFocus.dispose();
    referralFocus.dispose();
    gstNumberFocus.dispose();
    companyNameFocus.dispose();
    addressFocus.dispose();

    // New address focus nodes
    addressNameFocus.dispose();
    addressDetailsFocus.dispose();
    contactNameFocus.dispose();
    contactPhoneFocus.dispose();
    noteToDriverFocus.dispose();
  }
}
