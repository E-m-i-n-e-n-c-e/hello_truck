import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_truck_app/pages/otp_verification_page.dart';
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
  final _formKey = GlobalKey<FormState>();
  final _loadingState = ValueNotifier<bool>(false);
  final FocusNode _phoneFocusNode = FocusNode();
  bool _hasFocus = false;  // Track focus state locally

  @override
  void initState() {
    super.initState();
    _phoneFocusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    final newHasFocus = _phoneFocusNode.hasFocus;
    if (_hasFocus != newHasFocus) {
      setState(() => _hasFocus = newHasFocus);
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _loadingState.dispose();
    _phoneFocusNode.removeListener(_onFocusChange);
    _phoneFocusNode.dispose();
    _formKey.currentState?.dispose();
    super.dispose();
  }

  // Send OTP and show verification bottom sheet
  Future<void> _sendOtp(API api) async {
    if (!_formKey.currentState!.validate()) return;

    _loadingState.value = true;
    try {
      final phoneNumber = _phoneController.text.trim();
      await api.sendOtp(phoneNumber);

      if (!mounted) return;

      await showModalBottomSheet<BuildContext>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        enableDrag: false,
        backgroundColor: Colors.white,
        builder: (context) => OtpVerificationPage(phoneNumber: phoneNumber),
      );
    } catch (e) {
      if (!mounted) return;
      print('Error sending OTP: $e');
      SnackBars.error(context, 'Error sending OTP: ${e.toString()}');
    } finally {
      if (mounted) {
        _loadingState.value = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    // Only watch API when needed
    final api = ref.watch(apiProvider.select((value) => value.value));

    return PopScope(
      canPop: !_hasFocus,  // Use local focus state
      onPopInvokedWithResult: (didPop, result) {
        _phoneFocusNode.unfocus();
      },
      child: GestureDetector(
        onTap: () => _phoneFocusNode.unfocus(),
        child: Scaffold(
          backgroundColor: Colors.white,
          body: Stack(
            children: [
              _buildMainContent(textTheme, colorScheme, api),
              _buildLoadingOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  // Extract main content to avoid rebuilds from loading state
  Widget _buildMainContent(TextTheme textTheme, ColorScheme colorScheme, API? api) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              _buildTitle(textTheme),
              const SizedBox(height: 12),
              _buildSubtitle(textTheme),
              const SizedBox(height: 40),
              _buildPhoneInput(textTheme, colorScheme),
              const Spacer(),
              _buildSendOtpButton(textTheme, colorScheme, api),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return ValueListenableBuilder<bool>(
      valueListenable: _loadingState,
      builder: (context, isLoading, _) {
        return IgnorePointer(
          ignoring: !isLoading,
          child: AnimatedOpacity(
            opacity: isLoading ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: Stack(
              children: [
                ModalBarrier(
                  dismissible: false,
                  color: Colors.black.withValues(alpha: 0.3),
                ),
                const Center(child: CircularProgressIndicator()),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTitle(TextTheme textTheme) {
    return Text(
      'Enter your phone number',
      style: textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildSubtitle(TextTheme textTheme) {
    return Text(
      "We'll send you a verification code",
      style: textTheme.titleMedium?.copyWith(
        color: Colors.black54,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildPhoneInput(TextTheme textTheme, ColorScheme colorScheme) {
    return TextFormField(
      controller: _phoneController,
      focusNode: _phoneFocusNode,
      keyboardType: TextInputType.phone,
      style: textTheme.titleMedium?.copyWith(
        letterSpacing: 1.5
      ),
      decoration: InputDecoration(
        prefixIcon: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          margin: const EdgeInsets.only(right: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '+91',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                height: 24,
                width: 1,
                color: Colors.grey.shade300,
              ),
            ],
          ),
        ),
        hintText: 'Phone Number',
        hintStyle: TextStyle(
          color: Colors.grey.shade400,
          fontWeight: FontWeight.w500,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.error, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
        counterText: '',
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
    );
  }

  Widget _buildSendOtpButton(TextTheme textTheme, ColorScheme colorScheme, API? api) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 80.0),
      child: ValueListenableBuilder<bool>(
        valueListenable: _loadingState,
        builder: (context, isLoading, child) {
          return ElevatedButton(
            onPressed: isLoading ? null : () => _sendOtp(api!),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.secondary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              minimumSize: const Size(double.infinity, 56),
              elevation: 0,
            ),
            child: Text(
              'Send OTP',
              style: textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        },
      ),
    );
  }
}
