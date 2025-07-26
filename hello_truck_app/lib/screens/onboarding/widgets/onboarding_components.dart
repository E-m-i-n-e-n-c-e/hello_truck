import 'package:flutter/material.dart';
import 'package:hello_truck_app/screens/onboarding/controllers/onboarding_controller.dart';

class OnboardingStepContainer extends StatelessWidget {
  final OnboardingController controller;
  final Widget child;

  const OnboardingStepContainer({
    super.key,
    required this.controller,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller.fadeAnimation,
      builder: (context, _) {
        return FadeTransition(
          opacity: controller.fadeAnimation,
          child: SlideTransition(
            position: controller.slideAnimation,
            child: ScaleTransition(
              scale: controller.scaleAnimation,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}

class OnboardingStepIcon extends StatelessWidget {
  final OnboardingController controller;
  final IconData icon;
  final Color? color;

  const OnboardingStepIcon({
    super.key,
    required this.controller,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: controller.scaleAnimation,
      builder: (context, _) {
        return Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color ?? colorScheme.secondary,
                  (color ?? colorScheme.secondary).withValues(alpha: 0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: (color ?? colorScheme.secondary).withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 36,
              color: colorScheme.onSecondary,
            ),
          ),
        );
      },
    );
  }
}

class OnboardingStepTitle extends StatelessWidget {
  final OnboardingController controller;
  final String title;

  const OnboardingStepTitle({
    super.key,
    required this.controller,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: controller.fadeAnimation,
      builder: (context, _) {
        return Text(
          title,
          style: textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
        );
      },
    );
  }
}

class OnboardingStepDescription extends StatelessWidget {
  final OnboardingController controller;
  final String description;

  const OnboardingStepDescription({
    super.key,
    required this.controller,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: controller.fadeAnimation,
      builder: (context, _) {
        return Text(
          description,
          style: textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.7),
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        );
      },
    );
  }
}

class OnboardingTextField extends StatefulWidget {
  final OnboardingController controller;
  final TextEditingController textController;
  final FocusNode focusNode;
  final String label;
  final String hint;
  final IconData icon;
  final bool isRequired;
  final bool obscureText;
  final TextInputType keyboardType;
  final Function(String)? onSubmitted;
  final String? Function(String?)? validator;
  final int maxLines;

  const OnboardingTextField({
    super.key,
    required this.controller,
    required this.textController,
    required this.focusNode,
    required this.label,
    required this.hint,
    required this.icon,
    this.isRequired = false,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.onSubmitted,
    this.validator,
    this.maxLines = 1,
  });

  @override
  State<OnboardingTextField> createState() => _OnboardingTextFieldState();
}

class _OnboardingTextFieldState extends State<OnboardingTextField>
    with SingleTickerProviderStateMixin {
  late AnimationController _focusAnimationController;
  late Animation<double> _focusAnimation;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _focusAnimation = CurvedAnimation(
      parent: _focusAnimationController,
      curve: Curves.easeInOut,
    );

    widget.focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    _focusAnimationController.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = widget.focusNode.hasFocus;
      if (_isFocused) {
        _focusAnimationController.forward();
      } else {
        _focusAnimationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: widget.controller.slideAnimation,
      builder: (context, _) {
        return AnimatedBuilder(
          animation: _focusAnimation,
          builder: (context, _) {
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: _isFocused
                    ? [
                        BoxShadow(
                          color: colorScheme.secondary.withValues(alpha: 0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: TextFormField(
                controller: widget.textController,
                focusNode: widget.focusNode,
                obscureText: widget.obscureText,
                keyboardType: widget.keyboardType,
                maxLines: widget.maxLines,
                onFieldSubmitted: widget.onSubmitted,
                validator: widget.validator,
                decoration: InputDecoration(
                  labelText: widget.label,
                  hintText: widget.hint,
                  prefixIcon: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      widget.icon,
                      color: _isFocused
                          ? colorScheme.secondary
                          : colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  suffixIcon: widget.isRequired
                      ? Icon(
                          Icons.star,
                          size: 8,
                          color: colorScheme.error,
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: colorScheme.outline.withValues(alpha: 0.3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: colorScheme.outline.withValues(alpha: 0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: colorScheme.secondary,
                      width: 2,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: colorScheme.error,
                    ),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: colorScheme.error,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: _isFocused
                      ? colorScheme.secondary.withValues(alpha: 0.05)
                      : colorScheme.surface,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
