import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/design_system.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [
              Color(0xFF1A2A44), // Slightly lighter navy
              MithaqColors.navy,
            ],
          ),
        ),
        child: Stack(
          children: [
            // Background Decorative Elements
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: MithaqColors.mint.withValues(alpha: 0.05),
                ),
              ),
            ),

            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),

                    // The Animated Logo
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: ScaleTransition(
                        scale: _fadeAnimation,
                        child: Container(
                          padding: const EdgeInsets.all(30),
                          child: Image.asset(
                            'assets/logo_transparent.png',
                            width: 250,
                            height: 250,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                Image.asset(
                                  'assets/logo_icon.png',
                                  width: 250,
                                  height: 250,
                                  fit: BoxFit.contain,
                                ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 50),

                    // Welcome Text
                    SlideTransition(
                      position: _slideAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          children: [
                            Text(
                              'مرحباً بك في ميثاق',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.amiri(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 15),
                            Text(
                              'خطوتك الأولى نحو بناء أسرة مسلمة على أسس من الستر والجدية والسكينة',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white.withValues(alpha: 0.8),
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Action Buttons
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        children: [
                          _buildPremiumButton(
                            context,
                            'ابدأ الرحلةالآن',
                            onTap: () => context.go('/auth'),
                          ),
                          const SizedBox(height: 20),
                          TextButton(
                            onPressed: () {
                              // Show more info or terms
                            },
                            child: Text(
                              'تعرف على بروتوكول ميثاق',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumButton(
    BuildContext context,
    String text, {
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [MithaqColors.mint, MithaqColors.mint.withValues(alpha: 0.8)],
        ),
        boxShadow: [
          BoxShadow(
            color: MithaqColors.mint.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Center(
            child: Text(
              text,
              style: const TextStyle(
                color: MithaqColors.navy,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
