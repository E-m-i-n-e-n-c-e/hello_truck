import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AnimatedSplashScreen extends ConsumerStatefulWidget {
  final Color backgroundColor;

  const AnimatedSplashScreen({
    super.key,
    required this.backgroundColor,
  });

  @override
  ConsumerState<AnimatedSplashScreen> createState() => AnimatedSplashScreenState();
}

class AnimatedSplashScreenState extends ConsumerState<AnimatedSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  static final StateProvider<bool> isAnimationComplete = StateProvider<bool>((ref) => false);

  @override
  void initState() {
    super.initState();
    ref.read(isAnimationComplete.notifier).state = false;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
      ),
    );

    _animationController.forward();
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(milliseconds: 1000), () {
          ref.read(isAnimationComplete.notifier).state = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: widget.backgroundColor,
        body: Center(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated Hello Truck text
                  Transform.scale(
                    scale: 1.1,
                    child: const Text(
                      "Hello Truck",
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Text(
                      'Your Logistics Partner',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white.withValues(alpha: 0.8),
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  if(ref.watch(isAnimationComplete))
                    const CircularProgressIndicator(
                      color: Colors.white,
                    )
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}