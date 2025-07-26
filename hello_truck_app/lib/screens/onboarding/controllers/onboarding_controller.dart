import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hello_truck_app/models/gst_details.dart';

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

  // Focus Nodes
  final firstNameFocus = FocusNode();
  final lastNameFocus = FocusNode();
  final emailFocus = FocusNode();
  final referralFocus = FocusNode();
  final gstNumberFocus = FocusNode();
  final companyNameFocus = FocusNode();
  final addressFocus = FocusNode();

  // State Variables
  int _currentStep = 0;
  final int totalSteps = 4; // Personal Info, Email, Business Details (optional), Review
  bool _isLoading = false;
  bool _isBusiness = false;
  String? _googleIdToken;
  String? _userEmail;

  // State change notifiers
  VoidCallback? _onStateChanged;

  // Getters
  int get currentStep => _currentStep;
  bool get isLoading => _isLoading;
  bool get isBusiness => _isBusiness;
  String? get googleIdToken => _googleIdToken;
  String? get userEmail => _userEmail;

  OnboardingController({required TickerProvider vsync}) {
    _initializeAnimations(vsync);
  }

  void setStateChangeCallback(VoidCallback callback) {
    _onStateChanged = callback;
  }

  void _notifyStateChange() {
    _onStateChanged?.call();
  }

  void _initializeAnimations(TickerProvider vsync) {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: vsync,
    );

    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: vsync,
    );

    _scaleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: vsync,
    );

    fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOutQuart),
    );

    slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideAnimationController,
      curve: Curves.easeOutCubic,
    ));

    scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleAnimationController, curve: Curves.elasticOut),
    );

    startAnimations();
  }

  void startAnimations() {
    _animationController.forward();
    _slideAnimationController.forward();
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

  bool validateBusinessDetails() {
    if (!_isBusiness) return true;

    final gstNumber = gstNumberController.text.trim();
    final companyName = companyNameController.text.trim();
    final address = addressController.text.trim();

    if (gstNumber.isEmpty || companyName.isEmpty || address.isEmpty) {
      return false;
    }

    // Validate GST number format
    return RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$')
        .hasMatch(gstNumber);
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

  // Get total steps - always 4 steps: Personal, Email, Business, Review
  int getTotalSteps() {
    return 4; // Personal, Email, Business, Review
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

    firstNameFocus.dispose();
    lastNameFocus.dispose();
    emailFocus.dispose();
    referralFocus.dispose();
    gstNumberFocus.dispose();
    companyNameFocus.dispose();
    addressFocus.dispose();
  }
}
