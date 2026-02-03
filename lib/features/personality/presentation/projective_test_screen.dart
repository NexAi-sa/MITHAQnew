import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/design_system.dart';
import '../../../core/ui/design_tokens.dart';

/// Projective Personality Test Screen
/// Uses projective psychology techniques for compatibility analysis
class ProjectiveTestScreen extends ConsumerStatefulWidget {
  const ProjectiveTestScreen({super.key});

  @override
  ConsumerState<ProjectiveTestScreen> createState() =>
      _ProjectiveTestScreenState();
}

class _ProjectiveTestScreenState extends ConsumerState<ProjectiveTestScreen> {
  int _currentTest = 0;
  final Map<String, dynamic> _answers = {};
  bool _isComplete = false;

  // Test definitions
  final List<ProjectiveTest> _tests = [
    // Test 1: Perceptual Projection
    const ProjectiveTest(
      id: 'perception',
      title: 'ماذا رأيت أولًا؟',
      description: 'انظر للصورة التالية وأخبرنا: ما أول شيء لفت انتباهك؟',
      type: TestType.imageChoice,
      imageAsset: 'assets/images/projective_1.png',
      options: [
        TestOption(id: 'person', label: 'الشخص', icon: Icons.person),
        TestOption(id: 'path', label: 'الطريق', icon: Icons.route),
        TestOption(id: 'tree', label: 'الشجرة', icon: Icons.park),
        TestOption(id: 'sky', label: 'السماء', icon: Icons.cloud),
      ],
      analysis: {
        'person': {'trait': 'علاقاتي', 'desc': 'تركيزك على العلاقات الإنسانية'},
        'path': {'trait': 'تخطيطي', 'desc': 'اهتمامك بالمستقبل والأهداف'},
        'tree': {'trait': 'انسجامي', 'desc': 'ميلك للهدوء والطبيعة'},
        'sky': {'trait': 'حالم', 'desc': 'تفكيرك الواسع والطموح'},
      },
    ),
    // Test 2: Forest Scenario
    const ProjectiveTest(
      id: 'forest',
      title: 'سيناريو الغابة',
      description: 'تخيل أنك تمشي في غابة هادئة...',
      type: TestType.scenario,
      questions: [
        ScenarioQuestion(
          id: 'feeling',
          question: 'كيف تشعر في هذه الغابة؟',
          options: [
            TestOption(
              id: 'calm',
              label: 'مطمئن',
              icon: Icons.self_improvement,
            ),
            TestOption(id: 'curious', label: 'فضولي', icon: Icons.search),
            TestOption(id: 'cautious', label: 'حذر', icon: Icons.visibility),
            TestOption(
              id: 'anxious',
              label: 'متوتر',
              icon: Icons.warning_amber,
            ),
          ],
        ),
        ScenarioQuestion(
          id: 'companion',
          question: 'هل تمشي وحدك أم مع شخص؟',
          options: [
            TestOption(id: 'alone', label: 'وحدي', icon: Icons.person),
            TestOption(id: 'known', label: 'مع شخص أعرفه', icon: Icons.people),
            TestOption(
              id: 'unknown',
              label: 'مع شخص لا أعرفه',
              icon: Icons.person_add,
            ),
          ],
        ),
        ScenarioQuestion(
          id: 'reaction',
          question: 'ماذا تفعل إذا سمعت صوتًا مفاجئًا؟',
          options: [
            TestOption(
              id: 'observe',
              label: 'أتوقف وأراقب',
              icon: Icons.pause_circle,
            ),
            TestOption(
              id: 'continue',
              label: 'أكمّل المشي',
              icon: Icons.directions_walk,
            ),
            TestOption(
              id: 'investigate',
              label: 'أبحث عن المصدر',
              icon: Icons.search,
            ),
            TestOption(
              id: 'change',
              label: 'أغير الطريق',
              icon: Icons.alt_route,
            ),
          ],
        ),
      ],
    ),
    // Test 3: Empty Room
    const ProjectiveTest(
      id: 'room',
      title: 'الغرفة الفارغة',
      description: 'تخيل أنك تدخل غرفة فارغة تمامًا...',
      type: TestType.singleChoice,
      options: [
        TestOption(id: 'sit', label: 'أجلس', icon: Icons.chair),
        TestOption(id: 'search', label: 'أبحث عن شيء', icon: Icons.search),
        TestOption(id: 'window', label: 'أفتح النافذة', icon: Icons.window),
        TestOption(id: 'leave', label: 'أخرج مباشرة', icon: Icons.exit_to_app),
      ],
      analysis: {
        'sit': {'trait': 'تقبّل', 'desc': 'قدرة عالية على التأقلم والهدوء'},
        'search': {'trait': 'فضول', 'desc': 'رغبة في اكتشاف المعنى'},
        'window': {'trait': 'تغيير', 'desc': 'رغبة في التجديد والانفتاح'},
        'leave': {'trait': 'حسم', 'desc': 'عدم الارتياح للفراغ والغموض'},
      },
    ),
  ];

  @override
  Widget build(BuildContext context) {
    if (_isComplete) {
      return _buildResultsScreen();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: MithaqColors.navy),
          onPressed: () => _showExitConfirmation(),
        ),
        title: _buildProgressIndicator(),
        centerTitle: true,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.1, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: _buildCurrentTest(),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(_tests.length, (index) {
        final isActive = index == _currentTest;
        final isComplete = index < _currentTest;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 12,
          height: 8,
          decoration: BoxDecoration(
            color: isComplete
                ? MithaqColors.mint
                : isActive
                ? MithaqColors.navy
                : MithaqColors.navy.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _buildCurrentTest() {
    final test = _tests[_currentTest];

    return SingleChildScrollView(
      key: ValueKey(_currentTest),
      padding: const EdgeInsets.all(MithaqSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Test Number Badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: MithaqSpacing.m,
              vertical: MithaqSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: MithaqColors.mint.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(MithaqRadius.l),
            ),
            child: Text(
              'الاختبار ${_currentTest + 1} من ${_tests.length}',
              style: const TextStyle(
                color: MithaqColors.mint,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: MithaqSpacing.xl),

          // Title
          Text(
            test.title,
            style: const TextStyle(
              fontSize: MithaqTypography.titleLarge,
              fontWeight: FontWeight.bold,
              color: MithaqColors.navy,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: MithaqSpacing.m),

          // Description
          Text(
            test.description,
            style: TextStyle(
              fontSize: MithaqTypography.bodyLarge,
              color: MithaqColors.navy.withValues(alpha: 0.7),
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: MithaqSpacing.xxl),

          // Test Content based on type
          if (test.type == TestType.imageChoice) _buildImageChoiceTest(test),
          if (test.type == TestType.scenario) _buildScenarioTest(test),
          if (test.type == TestType.singleChoice) _buildSingleChoiceTest(test),
        ],
      ),
    );
  }

  Widget _buildImageChoiceTest(ProjectiveTest test) {
    return Column(
      children: [
        // Placeholder for projective image
        Container(
          height: 200,
          margin: const EdgeInsets.only(bottom: MithaqSpacing.xl),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                MithaqColors.navy.withValues(alpha: 0.1),
                MithaqColors.mint.withValues(alpha: 0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(MithaqRadius.l),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Abstract shapes representing path, person, tree, sky
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: MithaqColors.navy.withValues(alpha: 0.2),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(MithaqRadius.l),
                      bottomRight: Radius.circular(MithaqRadius.l),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 40,
                child: Icon(
                  Icons.cloud,
                  size: 40,
                  color: MithaqColors.mint.withValues(alpha: 0.5),
                ),
              ),
              Positioned(
                right: 60,
                top: 80,
                child: Icon(
                  Icons.park,
                  size: 50,
                  color: MithaqColors.mint.withValues(alpha: 0.7),
                ),
              ),
              Positioned(
                left: 80,
                bottom: 60,
                child: Icon(
                  Icons.person,
                  size: 45,
                  color: MithaqColors.navy.withValues(alpha: 0.6),
                ),
              ),
              Center(
                child: Container(
                  width: 3,
                  height: 80,
                  color: MithaqColors.navy.withValues(alpha: 0.3),
                ),
              ),
            ],
          ),
        ),

        // Options
        _buildOptionsGrid(test.options, test.id),
      ],
    );
  }

  Widget _buildScenarioTest(ProjectiveTest test) {
    return Column(
      children: [
        // Forest illustration
        Container(
          height: 150,
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: MithaqSpacing.xl),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF2D5A3D).withValues(alpha: 0.2),
                const Color(0xFF4A7C59).withValues(alpha: 0.2),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(MithaqRadius.l),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Icon(
                Icons.park,
                size: 50,
                color: const Color(0xFF2D5A3D).withValues(alpha: 0.6),
              ),
              Icon(
                Icons.park,
                size: 70,
                color: const Color(0xFF2D5A3D).withValues(alpha: 0.8),
              ),
              Icon(
                Icons.park,
                size: 50,
                color: const Color(0xFF2D5A3D).withValues(alpha: 0.6),
              ),
            ],
          ),
        ),

        // Scenario questions
        ...test.questions!.asMap().entries.map((entry) {
          final q = entry.value;
          final qIndex = entry.key;
          final selectedAnswer = _answers['${test.id}_${q.id}'];

          return Container(
            margin: const EdgeInsets.only(bottom: MithaqSpacing.l),
            padding: const EdgeInsets.all(MithaqSpacing.m),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(MithaqRadius.m),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: selectedAnswer != null
                            ? MithaqColors.mint
                            : MithaqColors.navy.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: selectedAnswer != null
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 16,
                              )
                            : Text(
                                '${qIndex + 1}',
                                style: const TextStyle(
                                  color: MithaqColors.navy,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: MithaqSpacing.s),
                    Expanded(
                      child: Text(
                        q.question,
                        style: const TextStyle(
                          fontSize: MithaqTypography.bodyLarge,
                          fontWeight: FontWeight.w600,
                          color: MithaqColors.navy,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: MithaqSpacing.m),
                Wrap(
                  spacing: MithaqSpacing.s,
                  runSpacing: MithaqSpacing.s,
                  children: q.options.map((option) {
                    final isSelected = selectedAnswer == option.id;
                    return ChoiceChip(
                      label: Text(option.label),
                      selected: isSelected,
                      selectedColor: MithaqColors.mint.withValues(alpha: 0.2),
                      checkmarkColor: MithaqColors.mint,
                      avatar: Icon(
                        option.icon,
                        size: 18,
                        color: isSelected
                            ? MithaqColors.mint
                            : MithaqColors.navy,
                      ),
                      onSelected: (_) {
                        HapticFeedback.lightImpact();
                        setState(() {
                          _answers['${test.id}_${q.id}'] = option.id;
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        }),

        const SizedBox(height: MithaqSpacing.m),

        // Continue button for scenario
        if (_isScenarioComplete(test))
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _goToNextTest,
              style: ElevatedButton.styleFrom(
                backgroundColor: MithaqColors.navy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: MithaqSpacing.m),
              ),
              child: const Text('التالي'),
            ),
          ),
      ],
    );
  }

  Widget _buildSingleChoiceTest(ProjectiveTest test) {
    return Column(
      children: [
        // Empty room illustration
        Container(
          height: 150,
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: MithaqSpacing.xl),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.grey.shade200, Colors.grey.shade100],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(MithaqRadius.l),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.meeting_room, size: 60, color: Colors.grey.shade400),
              const SizedBox(height: MithaqSpacing.s),
              Text(
                'غرفة فارغة',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
              ),
            ],
          ),
        ),

        // Single choice question
        const Text(
          'ما أول شيء تسويه؟',
          style: TextStyle(
            fontSize: MithaqTypography.titleSmall,
            fontWeight: FontWeight.w600,
            color: MithaqColors.navy,
          ),
        ),
        const SizedBox(height: MithaqSpacing.l),

        _buildOptionsGrid(test.options, test.id),
      ],
    );
  }

  Widget _buildOptionsGrid(List<TestOption> options, String testId) {
    final selectedAnswer = _answers[testId];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: MithaqSpacing.m,
      crossAxisSpacing: MithaqSpacing.m,
      childAspectRatio: 1.5,
      children: options.map((option) {
        final isSelected = selectedAnswer == option.id;
        return InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            setState(() {
              _answers[testId] = option.id;
            });
            // Auto advance after selection
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) _goToNextTest();
            });
          },
          borderRadius: BorderRadius.circular(MithaqRadius.m),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected
                  ? MithaqColors.mint.withValues(alpha: 0.1)
                  : Colors.white,
              borderRadius: BorderRadius.circular(MithaqRadius.m),
              border: Border.all(
                color: isSelected ? MithaqColors.mint : Colors.grey.shade200,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: MithaqColors.mint.withValues(alpha: 0.2),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  option.icon,
                  size: 32,
                  color: isSelected ? MithaqColors.mint : MithaqColors.navy,
                ),
                const SizedBox(height: MithaqSpacing.s),
                Text(
                  option.label,
                  style: TextStyle(
                    color: isSelected ? MithaqColors.mint : MithaqColors.navy,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  bool _isScenarioComplete(ProjectiveTest test) {
    if (test.questions == null) return false;
    for (final q in test.questions!) {
      if (_answers['${test.id}_${q.id}'] == null) return false;
    }
    return true;
  }

  void _goToNextTest() {
    if (_currentTest < _tests.length - 1) {
      setState(() {
        _currentTest++;
      });
    } else {
      setState(() {
        _isComplete = true;
      });
    }
  }

  Widget _buildResultsScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(MithaqSpacing.l),
          child: Column(
            children: [
              const SizedBox(height: MithaqSpacing.xl),

              // Success animation placeholder
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [MithaqColors.mint, Color(0xFF34D399)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: MithaqColors.mint.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.psychology,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: MithaqSpacing.xl),

              const Text(
                'تم تحليل شخصيتك بنجاح! ✨',
                style: TextStyle(
                  fontSize: MithaqTypography.titleLarge,
                  fontWeight: FontWeight.bold,
                  color: MithaqColors.navy,
                ),
              ),
              const SizedBox(height: MithaqSpacing.m),

              Text(
                'الآن سيساعدك مستشار التوافق في إيجاد شريك العمر المناسب بناءً على تحليل شخصيتك.',
                style: TextStyle(
                  fontSize: MithaqTypography.bodyLarge,
                  color: MithaqColors.navy.withValues(alpha: 0.7),
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: MithaqSpacing.xxl),

              // Result insights
              Container(
                padding: const EdgeInsets.all(MithaqSpacing.l),
                decoration: BoxDecoration(
                  color: MithaqColors.navy.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(MithaqRadius.l),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.auto_awesome, color: MithaqColors.mint),
                        SizedBox(width: MithaqSpacing.s),
                        Text(
                          'ما اكتشفناه عنك',
                          style: TextStyle(
                            fontSize: MithaqTypography.titleSmall,
                            fontWeight: FontWeight.bold,
                            color: MithaqColors.navy,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: MithaqSpacing.m),
                    Text(
                      _generatePersonalityInsight(),
                      style: TextStyle(
                        fontSize: MithaqTypography.bodyMedium,
                        color: MithaqColors.navy.withValues(alpha: 0.8),
                        height: 1.8,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MithaqSpacing.xl),

              // Disclaimer
              Container(
                padding: const EdgeInsets.all(MithaqSpacing.m),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(MithaqRadius.m),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.amber.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: MithaqSpacing.s),
                    Expanded(
                      child: Text(
                        'هذا الاختبار ليس تشخيصًا نفسيًا، بل أداة لفهم التوافق الشخصي.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.amber.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MithaqSpacing.xxl),

              // Action buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.go('/seeker/home'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MithaqColors.navy,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: MithaqSpacing.m,
                    ),
                  ),
                  child: const Text('استكشف الملفات المتوافقة'),
                ),
              ),
              const SizedBox(height: MithaqSpacing.m),

              TextButton(
                onPressed: () => context.pop(),
                child: const Text('العودة لحسابي'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _generatePersonalityInsight() {
    // Generate insight based on answers
    // Following Mithaq AI Guidelines: warm, non-judgmental, culturally appropriate
    final perception = _answers['perception'] ?? 'person';
    final feeling = _answers['forest_feeling'] ?? 'calm';
    final companion = _answers['forest_companion'] ?? 'known';
    final reaction = _answers['forest_reaction'] ?? 'observe';
    final room = _answers['room'] ?? 'sit';

    // Build Layer 2: User-facing Insight (warm, 3-4 lines)
    StringBuffer insight = StringBuffer();

    // Opening based on perception (attention orientation)
    switch (perception) {
      case 'person':
        insight.write('يبدو أنك تميل للاهتمام بالعلاقات والروابط الإنسانية، ');
        break;
      case 'path':
        insight.write('يبدو أنك تميل للتفكير في المستقبل والتخطيط بوضوح، ');
        break;
      case 'tree':
        insight.write('يبدو أنك تقدّر الهدوء والانسجام مع البيئة المحيطة، ');
        break;
      case 'sky':
        insight.write('يبدو أن لديك تفكير واسع ورؤية شاملة للأمور، ');
        break;
    }

    // Safety level based on feeling
    switch (feeling) {
      case 'calm':
        insight.write(
          'وتشعر براحة داخلية تساعدك على التأقلم مع المواقف الجديدة. ',
        );
        break;
      case 'curious':
        insight.write('ولديك فضول طبيعي يدفعك للاستكشاف والتعلم. ');
        break;
      case 'cautious':
        insight.write('وتفضل التأني والتفكير قبل اتخاذ القرارات. ');
        break;
      case 'anxious':
        insight.write('وتقدّر الوضوح والبيئات المألوفة. ');
        break;
    }

    insight.write('\n\n');

    // Compatibility hint based on companion preference
    switch (companion) {
      case 'alone':
        insight.write(
          'غالبًا ترتاح مع شخص يحترم مساحتك الشخصية ويقدّر استقلاليتك',
        );
        break;
      case 'known':
        insight.write('غالبًا ترتاح مع شخص تشعر معه بالألفة والأمان');
        break;
      case 'unknown':
        insight.write('غالبًا ترتاح مع شخص منفتح ومستعد للتجارب الجديدة');
        break;
    }

    // Add decision style based on reaction
    switch (reaction) {
      case 'observe':
        insight.write('، ويتميز بالتروي والملاحظة.');
        break;
      case 'continue':
        insight.write('، ويتميز بالثبات والاستمرارية.');
        break;
      case 'investigate':
        insight.write('، ويشاركك الفضول والبحث.');
        break;
      case 'change':
        insight.write('، ويتميز بالمرونة والتكيف.');
        break;
    }

    // Add closing based on room choice (comfort with uncertainty)
    switch (room) {
      case 'sit':
        insight.write(
          '\n\nتتقبل الأمور بهدوء وصبر، وهذا يساعدك على بناء علاقة مستقرة.',
        );
        break;
      case 'search':
        insight.write(
          '\n\nتبحث دائمًا عن معنى وهدف، وهذا يثري حياتك المشتركة.',
        );
        break;
      case 'window':
        insight.write('\n\nترحب بالتغيير والتجديد، وهذا يضيف حيوية للعلاقة.');
        break;
      case 'leave':
        insight.write(
          '\n\nتفضل الوضوح والحسم، وهذا يساعد على اتخاذ قرارات واضحة.',
        );
        break;
    }

    return insight.toString();
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('هل تريد الخروج؟'),
        content: const Text('سيتم فقدان تقدمك في الاختبار.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('متابعة'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.pop();
            },
            child: const Text('خروج', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// Data models
enum TestType { imageChoice, scenario, singleChoice }

class ProjectiveTest {
  final String id;
  final String title;
  final String description;
  final TestType type;
  final String? imageAsset;
  final List<TestOption> options;
  final List<ScenarioQuestion>? questions;
  final Map<String, dynamic>? analysis;

  const ProjectiveTest({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.imageAsset,
    this.options = const [],
    this.questions,
    this.analysis,
  });
}

class TestOption {
  final String id;
  final String label;
  final IconData icon;

  const TestOption({required this.id, required this.label, required this.icon});
}

class ScenarioQuestion {
  final String id;
  final String question;
  final List<TestOption> options;

  const ScenarioQuestion({
    required this.id,
    required this.question,
    required this.options,
  });
}
