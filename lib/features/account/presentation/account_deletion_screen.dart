import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:confetti/confetti.dart';
import '../../../core/theme/design_system.dart';
import '../../../core/ui/design_tokens.dart';
import '../../../core/ui/components/mithaq_card.dart';
import '../../../core/session/session_provider.dart';
import '../../seeker/data/profile_repository.dart';

/// Deletion reasons
enum DeletionReason {
  marriedViaApp('تزوجت عن طريق التطبيق', true),
  marriedOutside('تزوجت خارج التطبيق', true),
  notUseful('ما استفدت منه', false),
  harassment('تعرضت لإزعاجات', false);

  final String label;
  final bool isCelebration;
  const DeletionReason(this.label, this.isCelebration);
}

/// Account Deletion Screen with reason selection and celebration flow
class AccountDeletionScreen extends ConsumerStatefulWidget {
  const AccountDeletionScreen({super.key});

  @override
  ConsumerState<AccountDeletionScreen> createState() =>
      _AccountDeletionScreenState();
}

class _AccountDeletionScreenState extends ConsumerState<AccountDeletionScreen> {
  DeletionReason? _selectedReason;
  final _feedbackController = TextEditingController();
  bool _isDeleting = false;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('حذف الحساب'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(MithaqSpacing.m),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Warning Card
                _buildWarningCard(),
                const SizedBox(height: MithaqSpacing.xl),

                // Reason Selection
                _buildReasonSection(),
                const SizedBox(height: MithaqSpacing.l),

                // Feedback (optional)
                _buildFeedbackSection(),
                const SizedBox(height: MithaqSpacing.xl),

                // Delete Button
                _buildDeleteButton(),
                const SizedBox(height: MithaqSpacing.xxl),
              ],
            ),
          ),

          // Confetti overlay
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                MithaqColors.mint,
                MithaqColors.pink,
                Color(0xFFFFD700),
                Colors.white,
              ],
              numberOfParticles: 30,
              gravity: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningCard() {
    return Container(
      padding: const EdgeInsets.all(MithaqSpacing.m),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(MithaqRadius.m),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 32),
          const SizedBox(width: MithaqSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'تحذير مهم',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: MithaqTypography.bodyLarge,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'حذف الحساب نهائي ولا يمكن التراجع عنه. سيتم إزالة جميع بياناتك.',
                  style: TextStyle(
                    color: Colors.red.withValues(alpha: 0.8),
                    fontSize: MithaqTypography.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReasonSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'السبب (اختياري لكن يساعدنا في التحسين)',
          style: TextStyle(
            color: MithaqColors.navy,
            fontWeight: FontWeight.w600,
            fontSize: MithaqTypography.bodyLarge,
          ),
        ),
        const SizedBox(height: MithaqSpacing.m),
        ...DeletionReason.values.map(
          (reason) => MithaqCard(
            padding: EdgeInsets.zero,
            onTap: () => setState(() => _selectedReason = reason),
            child: ListTile(
              leading: Radio<DeletionReason>(
                // ignore: deprecated_member_use
                value: reason,
                // ignore: deprecated_member_use
                groupValue: _selectedReason,
                activeColor: reason.isCelebration
                    ? MithaqColors.mint
                    : Colors.red,
                // ignore: deprecated_member_use
                onChanged: (value) => setState(() => _selectedReason = value),
              ),
              title: Text(reason.label),
              onTap: () => setState(() => _selectedReason = reason),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeedbackSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ملاحظات إضافية (اختياري)',
          style: TextStyle(
            color: MithaqColors.navy.withValues(alpha: 0.7),
            fontSize: MithaqTypography.bodySmall,
          ),
        ),
        const SizedBox(height: MithaqSpacing.s),
        TextField(
          controller: _feedbackController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'شاركنا رأيك لنتحسن...',
            filled: true,
            fillColor: MithaqColors.navy.withValues(alpha: 0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(MithaqRadius.m),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeleteButton() {
    return ElevatedButton(
      onPressed: _isDeleting ? null : _handleDelete,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: MithaqSpacing.m),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MithaqRadius.m),
        ),
      ),
      child: _isDeleting
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Text(
              'حذف الحساب نهائياً',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: MithaqTypography.bodyLarge,
              ),
            ),
    );
  }

  Future<void> _handleDelete() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text(
          'هل أنت متأكد من رغبتك في حذف حسابك نهائياً؟\nهذا الإجراء لا يمكن التراجع عنه.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('نعم، احذف'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isDeleting = true);

    try {
      // Call repository to delete account
      final repository = ref.read(profileRepositoryProvider);
      final session = ref.read(sessionProvider);

      if (session.userId != null) {
        await repository.deleteAccount(
          session.userId!,
          reason: _selectedReason?.label,
          feedback: _feedbackController.text.isNotEmpty
              ? _feedbackController.text
              : null,
        );
      }

      // Check if celebration flow
      if (_selectedReason?.isCelebration == true) {
        await _showCelebration();
      } else {
        await _completeLogout();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('حدث خطأ: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  Future<void> _showCelebration() async {
    _confettiController.play();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 64)),
            const SizedBox(height: MithaqSpacing.m),
            const Text(
              'مبارك!',
              style: TextStyle(
                fontSize: MithaqTypography.titleLarge,
                fontWeight: FontWeight.bold,
                color: MithaqColors.navy,
              ),
            ),
            const SizedBox(height: MithaqSpacing.s),
            const Text(
              'نتمنى لك حياة سعيدة مليئة بالمودة والرحمة.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: MithaqColors.navy,
                fontSize: MithaqTypography.bodyMedium,
              ),
            ),
            const SizedBox(height: MithaqSpacing.s),
            Text(
              'شكراً لكونك جزءاً من ميثاق',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: MithaqColors.navy.withValues(alpha: 0.7),
                fontSize: MithaqTypography.bodySmall,
              ),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _completeLogout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: MithaqColors.mint,
              ),
              child: const Text('مع السلامة 👋'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _completeLogout() async {
    await ref.read(sessionProvider.notifier).resetSessionSafely();
    if (mounted) {
      context.go('/auth');
    }
  }
}
