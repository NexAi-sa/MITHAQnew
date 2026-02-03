import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/design_system.dart';
import '../../../core/ui/design_tokens.dart';
import '../application/advisor_controller.dart';
import '../../seeker/data/profile_repository.dart';

/// Sheet for looking up a profile by ID
class AdvisorProfileLookupSheet extends ConsumerStatefulWidget {
  const AdvisorProfileLookupSheet({super.key});

  @override
  ConsumerState<AdvisorProfileLookupSheet> createState() =>
      _AdvisorProfileLookupSheetState();
}

class _AdvisorProfileLookupSheetState
    extends ConsumerState<AdvisorProfileLookupSheet> {
  final _controller = TextEditingController();
  String? _errorMessage;
  bool _isFound = false;
  String? _foundProfileName;

  Future<void> _lookupProfile() async {
    final profileId = _controller.text.trim();
    if (profileId.isEmpty) {
      setState(() {
        _errorMessage = 'يرجى إدخال رقم الحساب';
        _isFound = false;
      });
      return;
    }

    final repository = ref.read(profileRepositoryProvider);
    final profile = await repository.getProfileById(profileId);

    if (profile == null) {
      setState(() {
        _errorMessage = 'لم يتم العثور على حساب بهذا الرقم';
        _isFound = false;
      });
    } else {
      setState(() {
        _errorMessage = null;
        _isFound = true;
        _foundProfileName = profile.name;
      });
    }
  }

  void _confirmAndClose() {
    final profileId = _controller.text.trim();
    ref.read(advisorControllerProvider.notifier).setTargetProfile(profileId);
    ref
        .read(advisorControllerProvider.notifier)
        .sendMessage('حلّل حساب $profileId');
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: MithaqSpacing.l,
        right: MithaqSpacing.l,
        top: MithaqSpacing.l,
        bottom: MediaQuery.of(context).padding.bottom + MithaqSpacing.l,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(MithaqRadius.xl),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: MithaqSpacing.l),

          // Title
          const Text(
            'البحث عن حساب',
            style: TextStyle(
              color: MithaqColors.navy,
              fontSize: MithaqTypography.titleSmall,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: MithaqSpacing.s),
          const Text(
            'أدخل رقم الحساب (Profile ID) لتحليل التوافق',
            style: TextStyle(
              color: Colors.grey,
              fontSize: MithaqTypography.bodySmall,
            ),
          ),
          const SizedBox(height: MithaqSpacing.l),

          // Input
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: 'مثال: p1',
              filled: true,
              fillColor: Colors.grey.withValues(alpha: 0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(MithaqRadius.m),
                borderSide: BorderSide.none,
              ),
              prefixIcon: const Icon(Icons.search, color: MithaqColors.navy),
              errorText: _errorMessage,
            ),
            onChanged: (_) {
              if (_errorMessage != null || _isFound) {
                setState(() {
                  _errorMessage = null;
                  _isFound = false;
                });
              }
            },
            onSubmitted: (_) => _lookupProfile(),
          ),
          const SizedBox(height: MithaqSpacing.m),

          // Found indicator
          if (_isFound)
            Container(
              padding: const EdgeInsets.all(MithaqSpacing.m),
              decoration: BoxDecoration(
                color: MithaqColors.mint.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(MithaqRadius.m),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: MithaqColors.mint),
                  const SizedBox(width: MithaqSpacing.s),
                  Text(
                    'تم العثور على: $_foundProfileName',
                    style: const TextStyle(
                      color: MithaqColors.navy,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: MithaqSpacing.l),

          // Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إلغاء'),
                ),
              ),
              const SizedBox(width: MithaqSpacing.m),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _isFound ? _confirmAndClose : _lookupProfile,
                  child: Text(_isFound ? 'تحليل الحساب' : 'بحث'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
