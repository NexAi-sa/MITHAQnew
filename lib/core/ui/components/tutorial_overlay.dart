import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../design_tokens.dart';

class TutorialOverlay extends StatefulWidget {
  final Widget child;
  final String tourId; // Unique ID to track if this specific tour was seen
  final List<TutorialStep> steps;

  const TutorialOverlay({
    super.key,
    required this.child,
    required this.tourId,
    required this.steps,
  });

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class TutorialStep {
  final String title;
  final String description;
  final GlobalKey? targetKey; // Widget to highlight (optional)
  final Alignment alignment;

  TutorialStep({
    required this.title,
    required this.description,
    this.targetKey,
    this.alignment = Alignment.center,
  });
}

class _TutorialOverlayState extends State<TutorialOverlay> {
  bool _showTour = false;
  int _currentStepIndex = 0;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeen = prefs.getBool('tour_${widget.tourId}') ?? false;
    if (!hasSeen && mounted) {
      // Short delay to allow UI to build
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() => _showTour = true);
      }
    }
  }

  Future<void> _finishTour() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tour_${widget.tourId}', true);
    if (mounted) {
      setState(() => _showTour = false);
    }
  }

  void _nextStep() {
    if (_currentStepIndex < widget.steps.length - 1) {
      setState(() => _currentStepIndex++);
    } else {
      _finishTour();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [widget.child, if (_showTour) _buildOverlay()]);
  }

  Widget _buildOverlay() {
    final step = widget.steps[_currentStepIndex];

    return Material(
      color: Colors.black.withValues(alpha: 0.7),
      child: InkWell(
        onTap: () {}, // Prevent clicks passing through
        child: Stack(
          children: [
            // Skip Button
            Positioned(
              top: 50,
              left: 20,
              child: TextButton(
                onPressed: _finishTour,
                child: const Text(
                  'تخطي',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),

            // Content
            Align(
              alignment: step.alignment,
              child: Padding(
                padding: const EdgeInsets.all(MithaqSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon or Image could go here
                    if (_currentStepIndex == 0)
                      const Icon(
                        Icons.waving_hand_rounded,
                        size: 60,
                        color: Colors.white,
                      ),

                    const SizedBox(height: MithaqSpacing.l),

                    Text(
                      step.title,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: MithaqSpacing.m),
                    Text(
                      step.description,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: MithaqSpacing.xl),

                    ElevatedButton(
                      onPressed: _nextStep,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                      ),
                      child: Text(
                        _currentStepIndex < widget.steps.length - 1
                            ? 'التالي'
                            : 'ابدأ الاستخدام',
                      ),
                    ),

                    const SizedBox(height: MithaqSpacing.m),
                    // Dots indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(widget.steps.length, (index) {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: index == _currentStepIndex
                                ? Colors.white
                                : Colors.white24,
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
