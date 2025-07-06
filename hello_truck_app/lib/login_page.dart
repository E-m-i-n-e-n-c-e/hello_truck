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
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Logo
                        Hero(
                          tag: 'app_logo',
                          child: Image.asset(
                            'assets/images/hello_truck.png',
                            height: 120,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // App Name
                        Text(
                          'Hello Truck',
                          style: textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),

                        // Tagline
                        Text(
                          'Your logistics partner',
                          style: textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 48),

                        // Phone Number Input
                        if (!_otpSent) ...[
                          Text(
                            'Enter your phone number',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _phoneController,
                            focusNode: _phoneFocusNode,
                            keyboardType: TextInputType.phone,
                            style: textTheme.bodyLarge,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.phone),
                              prefixText: '+91 ',
                              labelText: 'Mobile Number',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 16,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your mobile number';
                              }
                              if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) {
                                return 'Please enter a valid 10-digit mobile number';
                              }
                              return null;
                            },
                            maxLength: 10,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(10),
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                          ),
                          const SizedBox(height: 24),
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
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
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
                            'Enter the OTP sent to',
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          Text(
                            '+91 ${_phoneController.text}',
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _otpController,
                            focusNode: _otpFocusNode,
                            keyboardType: TextInputType.number,
                            style: textTheme.bodyLarge,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.lock_outline),
                              hintText: '6-digit OTP',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 16,
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
                          const SizedBox(height: 24),
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
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Verify OTP',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: _isLoading
                                ? null
                                : () {
                                    setState(() {
                                      _otpSent = false;
                                      _otpController.clear();
                                      _phoneController.clear();
                                    });
                                  },
                            child: Text(
                              'Change Phone Number',
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
                            child: Text(
                              _canResendOtp
                                ? 'Resend OTP'
                                : 'Resend OTP in ${_resendCountdown}s',
                              style: TextStyle(
                                color: _canResendOtp
                                  ? colorScheme.primary
                                  : colorScheme.onSurface.withValues(alpha: 0.5),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
