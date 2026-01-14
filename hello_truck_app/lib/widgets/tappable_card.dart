import 'package:flutter/material.dart';

/// A tappable wrapper with subtle opacity feedback instead of ink splash.
/// Provides a smooth, premium tap effect that avoids Material ink splash artifacts
/// during page transitions.
///
/// Use this for navigation cards, CTA buttons, and interactive containers
/// where you want a cleaner tap effect than the default Material splash.
class TappableCard extends StatefulWidget {
  /// The child widget to wrap with tap feedback.
  final Widget child;

  /// Callback when the card is tapped.
  final VoidCallback onTap;

  /// Opacity when pressed. Lower values create more dramatic feedback.
  /// Defaults to 0.6 (subtle but noticeable).
  final double pressedOpacity;

  /// Duration of the opacity animation.
  /// Defaults to 80ms for quick, responsive feel.
  final Duration animationDuration;

  const TappableCard({
    super.key,
    required this.child,
    required this.onTap,
    required this.pressedOpacity,
    required this.animationDuration,
  });

  @override
  State<TappableCard> createState() => _TappableCardState();
}

class _TappableCardState extends State<TappableCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _pressed = true);
      },
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedOpacity(
        duration: widget.animationDuration,
        opacity: _pressed ? widget.pressedOpacity : 1.0,
        child: widget.child,
      ),
    );
  }
}
