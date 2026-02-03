import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/session/session_provider.dart';
import '../../../core/theme/design_system.dart';
import '../../../core/ui/design_tokens.dart';
import '../../../core/safety/safety_repository.dart';

class AccountDeletionScreen extends ConsumerStatefulWidget {
  const AccountDeletionScreen({super.key});

  @override
  ConsumerState<AccountDeletionScreen> createState() =>
      _AccountDeletionScreenState();
}

class _AccountDeletionScreenState extends ConsumerState<AccountDeletionScreen> {
  String? _selectedReason;
  final TextEditingController _feedbackController = TextEditingController();
  bool _isLoading = false;

  final List<String> _reasons = [
    'تزوجت عن طريق التطبيق 🎉',
    'تزوجت خارج التطبيق 💍',
    'ما استفدت منه',
    'تعرضت لإزعاجات',
    'سبب آخر',
  ];

  void _handleDelete() {
    if (_selectedReason == null) return;

    // Show confirmation bottom sheet
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(MithaqRadius.xl),
        ),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(MithaqSpacing.l),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'تأكيد الحذف',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: MithaqSpacing.m),
              const Text(
                'هل أنت متأكد أنك تريد حذف حسابك وجميع بياناتك نهائياً؟ هذا الإجراء لا يمكن التراجع عنه.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: MithaqSpacing.l),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _finalizeDeletion();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('نعم، احذف حسابي'),
              ),
              const SizedBox(height: MithaqSpacing.s),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _finalizeDeletion() async {
    setState(() => _isLoading = true);
    try {
      final session = ref.read(sessionProvider);
      final userId = session.userId;
      if (userId == null) return;

      await ref
          .read(safetyRepositoryProvider)
          .deleteAccount(
            userId: userId,
            reason: _selectedReason!,
            feedback: _feedbackController.text,
          );
      await ref.read(sessionProvider.notifier).resetSessionSafely();
      if (mounted) {
        context.go('/auth');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('حدث خطأ أثناء حذف الحساب: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('قبل ما تودّعنا 🌱'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: MithaqColors.navy,
      ),
      body: ListView(
        padding: const EdgeInsets.all(MithaqSpacing.l),
        children: [
          const Text(
            'وش سبب حذف الحساب؟',
            style: TextStyle(
              fontSize: MithaqTypography.bodyLarge,
              fontWeight: FontWeight.bold,
              color: MithaqColors.navy,
            ),
          ),
          const SizedBox(height: MithaqSpacing.m),
          ..._reasons.map(
            (reason) => RadioListTile<String>(
              title: Text(reason),
              value: reason,
              // ignore: deprecated_member_use
              groupValue: _selectedReason,
              // ignore: deprecated_member_use
              onChanged: (val) => setState(() => _selectedReason = val),
              activeColor: MithaqColors.navy,
            ),
          ),
          const SizedBox(height: MithaqSpacing.l),
          const Text(
            'تحب تشاركنا رأيك أو اقتراحك؟ (اختياري)',
            style: TextStyle(
              fontSize: MithaqTypography.bodyMedium,
              color: MithaqColors.navy,
            ),
          ),
          const SizedBox(height: MithaqSpacing.s),
          TextField(
            controller: _feedbackController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'اكتب هنا...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(MithaqRadius.m),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(MithaqRadius.m),
                borderSide: const BorderSide(color: MithaqColors.navy),
              ),
            ),
          ),
          const SizedBox(height: MithaqSpacing.xl),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            ElevatedButton(
              onPressed: _selectedReason != null ? _handleDelete : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: MithaqColors.navy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: MithaqSpacing.m),
              ),
              child: const Text('حذف الحساب نهائياً'),
            ),
        ],
      ),
    );
  }
}

class _CelebrationDialog extends StatefulWidget {
  final VoidCallback onConfirm;
  const _CelebrationDialog({required this.onConfirm});

  @override
  State<_CelebrationDialog> createState() => _CelebrationDialogState();
}

class _CelebrationDialogState extends State<_CelebrationDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MithaqRadius.xl),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: _FireworksPainter(progress: _controller.value),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(MithaqSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'مبروك! 💖',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: MithaqColors.navy,
                  ),
                ),
                const SizedBox(height: MithaqSpacing.m),
                const Text(
                  'نتمنى لك حياة مليئة بالمودة والسكينة\nشكرًا لأنك كنت جزءًا من ميثاق',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: MithaqColors.navy),
                ),
                const SizedBox(height: MithaqSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: widget.onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MithaqColors.navy,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('إغلاق الحساب'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FireworksPainter extends CustomPainter {
  final double progress;
  _FireworksPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42);
    for (int i = 0; i < 5; i++) {
      final centerX = random.nextDouble() * size.width;
      final centerY = random.nextDouble() * size.height;
      final color = [
        MithaqColors.mint,
        MithaqColors.pink,
        Colors.orange,
      ][random.nextInt(3)];

      _drawExplosion(canvas, Offset(centerX, centerY), color, progress, random);
    }
  }

  void _drawExplosion(
    Canvas canvas,
    Offset center,
    Color color,
    double progress,
    math.Random random,
  ) {
    const particleCount = 12;
    const maxRadius = 50.0;

    // Simple pulse effect based on progress
    final t = (progress * 2) % 1.0;
    final opacity = 1.0 - t;
    final currentRadius = t * maxRadius;

    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < particleCount; i++) {
      final angle = (i * 2 * math.pi) / particleCount;
      final x = center.dx + math.cos(angle) * currentRadius;
      final y = center.dy + math.sin(angle) * currentRadius;
      canvas.drawCircle(Offset(x, y), 2.0, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _FireworksPainter oldDelegate) => true;
}
