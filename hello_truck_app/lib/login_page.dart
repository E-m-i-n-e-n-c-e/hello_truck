import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:hello_truck_app/auth/api.dart';
import 'package:hello_truck_app/auth/auth_providers.dart';
import 'package:hello_truck_app/widgets/snackbars.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final FocusNode _phoneFocusNode = FocusNode();
  final FocusNode _otpFocusNode = FocusNode();
  bool _isLoading = false;
  bool _otpSent = false;
  bool _canResendOtp = false;
  int _resendCountdown = 30;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    _phoneFocusNode.addListener(() {
      setState(() {});  // Trigger rebuild when focus changes
    });
    _otpFocusNode.addListener(() {
      setState(() {});  // Trigger rebuild when focus changes
    });
  }

  void _startResendTimer() {
    setState(() {
      _canResendOtp = false;
      _resendCountdown = 30;
    });

    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() {
          _resendCountdown--;
        });
      } else {
        setState(() {
          _canResendOtp = true;
        });
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _resendTimer?.cancel();
    _phoneFocusNode.dispose();
    _otpFocusNode.dispose();
    _formKey.currentState?.dispose();
    super.dispose();
  }

  // Send OTP
  Future<void> _sendOtp(API api) async {
    if (!_otpSent && !_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await api.sendOtp(_phoneController.text.trim());

      if (mounted) {
        SnackBars.success(context, 'OTP sent successfully!');
        setState(() {
          _otpSent = true;
          _isLoading = false;
        });
        _startResendTimer();
      }
    } catch (e) {
      if (mounted) {
        print('Error sending OTP: $e');
        SnackBars.error(context, 'Error sending OTP: ${e.toString()}');
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Verify OTP
  Future<void> _verifyOtp(API api) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await api.verifyOtp(
        _phoneController.text.trim(),
        _otpController.text.trim(),
      );
    } catch (e) {
      print('Error verifying OTP: $e');
      if (mounted) {
        _otpController.clear(); // Clear OTP field on error
        SnackBars.error(context, "Error verifying OTP: ${e.toString()}");
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final api = ref.watch(apiProvider);
    final size = MediaQuery.of(context).size;

    return PopScope(
      canPop: !_phoneFocusNode.hasFocus && !_otpFocusNode.hasFocus,
      onPopInvokedWithResult: (didPop, result) {
        FocusScope.of(context).unfocus();
      },
      child: GestureDetector(
        onTap: () {
            FocusScope.of(context).unfocus();
        },
        behavior: HitTestBehavior.opaque,
        child: Scaffold(
          backgroundColor: colorScheme.surface,
          body: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Top curved container with logo
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 40, 20, 40),
                    child: Column(
                      children: [
                        // Logo
                        Hero(
                          tag: 'app_logo',
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Image.asset(
                                'assets/images/logo.png',
                                height: 60,
                                width: 60,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // App Name
                        Text(
                          'Hello Truck',
                          style: textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Tagline
                        Text(
                          'Your logistics partner',
                          style: textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onPrimary.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Form section
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Title
                          Text(
                            _otpSent ? 'Verify OTP' : 'Login',
                            style: textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Subtitle
                          Text(
                            _otpSent
                                ? 'Enter the verification code sent to your phone'
                                : 'Enter your phone number to continue',
                            style: textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Phone Number Input
                          if (!_otpSent) ...[
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: colorScheme.primary.withValues(alpha: 0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: TextFormField(
                                controller: _phoneController,
                                focusNode: _phoneFocusNode,
                                keyboardType: TextInputType.phone,
                                style: textTheme.bodyLarge,
                                decoration: InputDecoration(
                                  prefixIcon: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    margin: const EdgeInsets.only(right: 8),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '+91',
                                          style: textTheme.bodyLarge?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          height: 24,
                                          width: 1,
                                          color: colorScheme.onSurface.withValues(alpha: 0.3),
                                        ),
                                      ],
                                    ),
                                  ),
                                  hintText: 'Phone Number',
                                  filled: true,
                                  fillColor: colorScheme.surface,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                    horizontal: 16,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your phone number';
                                  }
                                  if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) {
                                    return 'Please enter a valid 10-digit phone number';
                                  }
                                  return null;
                                },
                                maxLength: 10,
                                inputFormatters: [
                                  LengthLimitingTextInputFormatter(10),
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),
                            ElevatedButton(
                              onPressed: _isLoading
                                  ? null
                                  : () => _sendOtp(api.value!),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                foregroundColor: colorScheme.onPrimary,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                minimumSize: Size(size.width, 56),
                                elevation: 2,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Send OTP',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ],

                          // OTP Input
                          if (_otpSent) ...[
                            Text(
                              'OTP sent to',
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            Text(
                              '+91 ${_phoneController.text}',
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: colorScheme.primary.withValues(alpha: 0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: TextFormField(
                                controller: _otpController,
                                focusNode: _otpFocusNode,
                                keyboardType: TextInputType.number,
                                style: textTheme.headlineSmall?.copyWith(
                                  letterSpacing: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                                decoration: InputDecoration(
                                  hintText: '• • • • • •',
                                  hintStyle: textTheme.headlineSmall?.copyWith(
                                    color: colorScheme.onSurface.withValues(alpha: 0.3),
                                    letterSpacing: 8,
                                  ),
                                  filled: true,
                                  fillColor: colorScheme.surface,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 20,
                                    horizontal: 16,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter the OTP';
                                  }
                                  if (value.length != 6) {
                                    return 'OTP must be 6 digits';
                                  }
                                  return null;
                                },
                                maxLength: 6,
                                inputFormatters: [
                                  LengthLimitingTextInputFormatter(6),
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),
                            ElevatedButton(
                              onPressed: _isLoading
                                  ? null
                                  : () => _verifyOtp(api.value!),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                foregroundColor: colorScheme.onPrimary,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                minimumSize: Size(size.width, 56),
                                elevation: 2,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Verify & Continue',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 24),

                            // Action buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                TextButton.icon(
                                  onPressed: _isLoading
                                      ? null
                                      : () {
                                          setState(() {
                                            _otpSent = false;
                                            _otpController.clear();
                                          });
                                        },
                                  icon: Icon(
                                    Icons.arrow_back,
                                    size: 16,
                                    color: colorScheme.primary,
                                  ),
                                  label: Text(
                                    'Change Number',
                                    style: TextStyle(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: (_isLoading || !_canResendOtp)
                                      ? null
                                      : () => _sendOtp(api.value!),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.refresh,
                                        size: 16,
                                        color: _canResendOtp
                                            ? colorScheme.primary
                                            : colorScheme.onSurface.withValues(alpha: 0.5),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _canResendOtp
                                            ? 'Resend OTP'
                                            : '${_resendCountdown}s',
                                        style: TextStyle(
                                          color: _canResendOtp
                                              ? colorScheme.primary
                                              : colorScheme.onSurface.withValues(alpha: 0.5),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
