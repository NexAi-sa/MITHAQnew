import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/design_system.dart';
import '../../../core/ui/design_tokens.dart';
import '../domain/personality_test.dart';
import '../data/personality_analyzer.dart';
import '../../seeker/data/profile_repository.dart';

class PersonalityTestScreen extends ConsumerStatefulWidget {
  const PersonalityTestScreen({super.key});

  @override
  ConsumerState<PersonalityTestScreen> createState() =>
      _PersonalityTestScreenState();
}

class _PersonalityTestScreenState extends ConsumerState<PersonalityTestScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // Selected values
  PersonalitySilenceInterpretation? _selectedSilence;
  PersonalityHomeType? _selectedHome;
  final List<PriorityIcon> _selectedPriorities = [];
  PersonalityTestResult? _result;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MithaqColors.navy,
      body: SafeArea(
        child: Column(
          children: [
            _buildProgressBar(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildIntroStep(),
                  _buildSilenceStep(),
                  _buildHomeStep(),
                  _buildPrioritiesStep(),
                  if (_result != null) _buildResultStep(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.all(MithaqSpacing.m),
      child: Stack(
        children: [
          Container(
            height: 4,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            height: 4,
            width: MediaQuery.of(context).size.width * ((_currentStep + 1) / 5),
            decoration: BoxDecoration(
              color: MithaqColors.mint,
              borderRadius: BorderRadius.circular(2),
              boxShadow: [
                BoxShadow(
                  color: MithaqColors.mint.withValues(alpha: 0.4),
                  blurRadius: 10,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepTemplate({
    required String title,
    required String subtitle,
    required Widget content,
    VoidCallback? onNext,
    bool showNext = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: MithaqSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: MithaqSpacing.l),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: MithaqSpacing.s),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: MithaqSpacing.xl),
          Expanded(child: content),
          if (showNext)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: MithaqSpacing.xl),
              child: ElevatedButton(
                onPressed: onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: MithaqColors.mint,
                  foregroundColor: MithaqColors.navy,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'متابعة',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildIntroStep() {
    return _buildStepTemplate(
      title: 'حلل شخصيتك كشريك حياة بالذكاء الاصطناعي',
      subtitle:
          'اكتشف ما يبرمجه عقلك الباطن بصدق.. لا توجد إجابات صحيحة أو خاطئة، فقط ميولك البصرية.',
      content: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(MithaqSpacing.xl),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
                border: Border.all(
                  color: MithaqColors.mint.withValues(alpha: 0.2),
                ),
              ),
              child: const Icon(
                Icons.psychology,
                size: 80,
                color: MithaqColors.mint,
              ),
            ),
            const SizedBox(height: MithaqSpacing.xl),
            const Text(
              'سنعرض عليك بعض الصور والمواقف، اختر ما تشعر به عفوياً دون تفكير طويل.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, height: 1.6),
            ),
          ],
        ),
      ),
      onNext: () {
        setState(() => _currentStep = 1);
        _pageController.nextPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      },
    );
  }

  final TextEditingController _silenceDescriptionController =
      TextEditingController();

  Widget _buildSilenceStep() {
    return _buildStepTemplate(
      title: 'ديناميكية العلاقة',
      subtitle: 'صف شعورك للأشخاص في هذه الصورة بكلمة واحدة عفوية.',
      content: SingleChildScrollView(
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: AspectRatio(
                aspectRatio: 1.2,
                child: Image.asset(
                  'assets/images/personality/couple_silence.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: MithaqSpacing.xl),
            TextField(
              controller: _silenceDescriptionController,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 18),
              decoration: InputDecoration(
                hintText: 'اكتب الكلمة هنا...',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: MithaqColors.mint),
                ),
              ),
              onChanged: (val) {
                // Determine interpretation based on keywords (Mock NLP logic)
                final text = val.trim();
                if (text.isEmpty) {
                  setState(() => _selectedSilence = null);
                  return;
                }

                final positiveKeywords = [
                  'هدوء',
                  'تفاهم',
                  'سكينة',
                  'راحة',
                  'تأمل',
                  'حب',
                  'سلام',
                ];
                final negativeKeywords = [
                  'جفاء',
                  'ملل',
                  'حزن',
                  'برود',
                  'خوف',
                  'وحدة',
                  'قطيعة',
                  'تجاهل',
                ];

                bool isPositive = positiveKeywords.any((k) => text.contains(k));
                bool isNegative = negativeKeywords.any((k) => text.contains(k));

                if (isPositive) {
                  setState(
                    () => _selectedSilence =
                        PersonalitySilenceInterpretation.understanding,
                  );
                } else if (isNegative) {
                  setState(
                    () => _selectedSilence =
                        PersonalitySilenceInterpretation.apathy,
                  );
                } else {
                  // Default to understanding if neutral, but mark as interpreted
                  setState(
                    () => _selectedSilence =
                        PersonalitySilenceInterpretation.understanding,
                  );
                }
              },
            ),
            const SizedBox(height: MithaqSpacing.m),
            const SizedBox.shrink(),
          ],
        ),
      ),
      onNext: _selectedSilence == null
          ? null
          : () {
              setState(() => _currentStep = 2);
              _pageController.nextPage(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
              );
            },
    );
  }

  Widget _buildHomeStep() {
    return _buildStepTemplate(
      title: 'نمط الحياة والاحتياج',
      subtitle: 'أين تشعر بالأمان والراحة لقضاء حياتك؟',
      content: GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: MithaqSpacing.m,
        crossAxisSpacing: MithaqSpacing.m,
        children: [
          _buildHomeOption('بيت ريفي', PersonalityHomeType.rustic),
          _buildHomeOption('خيمة', PersonalityHomeType.camping),
          _buildHomeOption('قلعة', PersonalityHomeType.castle),
          _buildHomeOption('برج عصري', PersonalityHomeType.modern),
        ],
      ),
      onNext: _selectedHome == null
          ? null
          : () {
              setState(() => _currentStep = 3);
              _pageController.nextPage(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
              );
            },
    );
  }

  Widget _buildHomeOption(String label, PersonalityHomeType type) {
    final bool isSelected = _selectedHome == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedHome = type),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? MithaqColors.mint : Colors.white10,
            width: 2,
          ),
          color: isSelected
              ? MithaqColors.mint.withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.05),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getHomeIcon(type),
              color: isSelected ? MithaqColors.mint : Colors.white38,
              size: 40,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? MithaqColors.mint : Colors.white60,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getHomeIcon(PersonalityHomeType type) {
    switch (type) {
      case PersonalityHomeType.rustic:
        return Icons.home_rounded;
      case PersonalityHomeType.camping:
        return Icons.landscape_rounded;
      case PersonalityHomeType.castle:
        return Icons.fort_rounded;
      case PersonalityHomeType.modern:
        return Icons.location_city_rounded;
    }
  }

  Widget _buildPrioritiesStep() {
    return _buildStepTemplate(
      title: 'أولوياتك الحياتية',
      subtitle: 'اختر 3 أيقونات تعبر عنك ورتبها حسب الأهمية.',
      content: Column(
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: PriorityIcon.values.map((icon) {
              final int index = _selectedPriorities.indexOf(icon);
              final bool isSelected = index != -1;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedPriorities.remove(icon);
                    } else if (_selectedPriorities.length < 3) {
                      _selectedPriorities.add(icon);
                    }
                  });
                },
                child: Container(
                  width: 70,
                  height: 100,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? MithaqColors.mint.withValues(alpha: 0.1)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? MithaqColors.mint : Colors.white10,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _getPriorityIcon(icon),
                              color: isSelected
                                  ? MithaqColors.mint
                                  : Colors.white38,
                            ),
                            const SizedBox(height: 4),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Positioned(
                          top: 4,
                          left: 4,
                          child: CircleAvatar(
                            radius: 8,
                            backgroundColor: MithaqColors.mint,
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: MithaqColors.navy,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
      onNext: _selectedPriorities.length < 3
          ? null
          : () {
              _submitTest();
            },
    );
  }

  IconData _getPriorityIcon(PriorityIcon icon) {
    switch (icon) {
      case PriorityIcon.tree:
        return Icons.park_outlined;
      case PriorityIcon.house:
        return Icons.home_work_outlined;
      case PriorityIcon.swing:
        return Icons.child_care_rounded;
      case PriorityIcon.fence:
        return Icons.shield_outlined;
    }
  }

  void _submitTest() async {
    final result = PersonalityAnalyzer.analyze(
      silence: _selectedSilence!,
      home: _selectedHome!,
      priorities: _selectedPriorities,
    );

    setState(() {
      _result = result;
      _currentStep = 4;
    });

    _pageController.nextPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );

    // Save to Supabase
    final profile = ref.read(myProfileProvider).value;
    if (profile != null) {
      await ref
          .read(profileRepositoryProvider)
          .savePersonalityResult(profile.profileId, result);
      ref.invalidate(myProfileProvider);
    }
  }

  Widget _buildResultStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: MithaqSpacing.l,
        vertical: MithaqSpacing.xl,
      ),
      child: Column(
        children: [
          const Icon(
            Icons.verified_rounded,
            color: MithaqColors.mint,
            size: 60,
          ),
          const SizedBox(height: MithaqSpacing.m),
          const Text(
            'اكتمل التحليل بنجاح',
            style: TextStyle(
              color: MithaqColors.mint,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: MithaqSpacing.xl),
          Text(
            'نمطك هو: ${_result!.personalityTypeName}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: MithaqSpacing.xl),
          _buildInfoCard('تحليل شخصيتك', _result!.analysis),
          const SizedBox(height: MithaqSpacing.m),
          _buildInfoCard('الشريك المناسب لك', _result!.matchingAdvice),
          const SizedBox(height: MithaqSpacing.xxl),
          const SizedBox(height: MithaqSpacing.m),
          ElevatedButton.icon(
            onPressed: () {
              final text =
                  'نتيجتي في تحليل الشخصية من ميثاق ✨\n\n'
                  'نمطي هو: ${_result!.personalityTypeName}\n'
                  '${_result!.analysis}\n\n'
                  'حمل تطبيق ميثاق واكتشف شخصيتك كشريك حياة!';
              final box = context.findRenderObject() as RenderBox?;
              Share.share(
                text,
                sharePositionOrigin: box != null
                    ? box.localToGlobal(Offset.zero) & box.size
                    : const Rect.fromLTWH(0, 0, 100, 100),
              );
            },
            icon: const Icon(Icons.share_rounded),
            label: const Text('مشاركة النتيجة مع الآخرين'),
            style: ElevatedButton.styleFrom(
              backgroundColor: MithaqColors.mint,
              foregroundColor: MithaqColors.navy,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: MithaqSpacing.l),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'العودة للملف الشخصي',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String content) {
    return Container(
      padding: const EdgeInsets.all(MithaqSpacing.l),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: MithaqColors.mint,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(color: Colors.white70, height: 1.5),
          ),
        ],
      ),
    );
  }
}
