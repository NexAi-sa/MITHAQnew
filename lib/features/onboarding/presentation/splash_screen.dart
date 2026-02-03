import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/design_system.dart';

/// Premium Splash Screen with elegant logo animation
/// Conveys: Trust, Luxury, Gratitude, Privacy
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Logo animation controllers
  late AnimationController _logoController;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;

  // Glow animation controller
  late AnimationController _glowController;
  late Animation<double> _glowOpacity;

  // Text animation
  late AnimationController _textController;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;

  // Tagline animation
  late AnimationController _taglineController;
  late Animation<double> _taglineOpacity;

  // Flag to ensure animation runs only once
  bool _hasStartedAnimation = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Start animations only once after dependencies are available
    if (!_hasStartedAnimation) {
      _hasStartedAnimation = true;
      _startAnimationSequence();
    }
  }

  void _initAnimations() {
    // Logo animation: subtle scale + fade in
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _logoScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutCubic),
    );

    _logoOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _logoController, curve: Curves.easeOut));

    // Subtle glow pulse (once)
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _glowOpacity =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.6), weight: 50),
          TweenSequenceItem(tween: Tween(begin: 0.6, end: 0.0), weight: 50),
        ]).animate(
          CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
        );

    // App name text animation
    _textController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _textOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOut));

    _textSlide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
        );

    // Tagline animation
    _taglineController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _taglineController, curve: Curves.easeOut),
    );
  }

  Future<void> _startAnimationSequence() async {
    // Respect reduced motion accessibility
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    if (reduceMotion) {
      // Skip animations for accessibility
      _logoController.value = 1.0;
      _textController.value = 1.0;
      _taglineController.value = 1.0;
    } else {
      // Elegant animation sequence
      await Future.delayed(const Duration(milliseconds: 300));
      _logoController.forward();

      await Future.delayed(const Duration(milliseconds: 500));
      _glowController.forward();

      await Future.delayed(const Duration(milliseconds: 400));
      _textController.forward();

      await Future.delayed(const Duration(milliseconds: 300));
      _taglineController.forward();
    }

    // Navigate after animations complete
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) {
      context.go('/welcome');
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _glowController.dispose();
    _textController.dispose();
    _taglineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Premium immersive status bar
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      backgroundColor: MithaqColors.navy,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              MithaqColors.navy,
              MithaqColors.navy.withValues(alpha: 0.95),
              const Color(0xFF0A1628), // Deeper navy at bottom
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // Animated Logo with Glow
                AnimatedBuilder(
                  animation: Listenable.merge([
                    _logoController,
                    _glowController,
                  ]),
                  builder: (context, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        // Subtle glow behind logo
                        Opacity(
                          opacity: _glowOpacity.value,
                          child: Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: MithaqColors.mint.withValues(
                                    alpha: 0.4,
                                  ),
                                  blurRadius: 60,
                                  spreadRadius: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Main logo
                        Opacity(
                          opacity: _logoOpacity.value,
                          child: Transform.scale(
                            scale: _logoScale.value,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.1),
                                border: Border.all(
                                  color: MithaqColors.mint.withValues(
                                    alpha: 0.3,
                                  ),
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.handshake_rounded,
                                size: 64,
                                color: MithaqColors.mint,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 40),

                // App Name with slide animation
                SlideTransition(
                  position: _textSlide,
                  child: FadeTransition(
                    opacity: _textOpacity,
                    child: Text(
                      AppLocalizations.of(context, 'app_title'),
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Tagline
                FadeTransition(
                  opacity: _taglineOpacity,
                  child: Text(
                    'رحلتك نحو النصف الآخر',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.7),
                      letterSpacing: 1,
                    ),
                  ),
                ),

                const Spacer(flex: 2),

                // Subtle trust indicator
                FadeTransition(
                  opacity: _taglineOpacity,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 32),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shield_outlined,
                          size: 16,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'خصوصيتك أمانة',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
