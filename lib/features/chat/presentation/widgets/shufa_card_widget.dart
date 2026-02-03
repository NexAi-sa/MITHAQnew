import 'package:flutter/material.dart';
import '../../../../core/theme/design_system.dart';

class ShufaCardWidget extends StatelessWidget {
  final String guardianName;
  final String guardianTitle;
  final String contactPhone;
  final bool isVerified;

  const ShufaCardWidget({
    super.key,
    required this.guardianName,
    required this.guardianTitle,
    required this.contactPhone,
    this.isVerified = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              const Expanded(
                child: Text(
                  'بطاقة الشوفة الشرعية',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 48), // Spacer for balance
            ],
          ),
        ),

        // Card Body
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1A1F2C).withValues(alpha: 0.95),
                const Color(0xFF0D1117).withValues(alpha: 0.98),
              ],
            ),
            border: Border.all(
              color: MithaqColors.mint.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Pattern background (MITHAQ watermark)
              Positioned(
                bottom: 40,
                left: 24,
                child: Text(
                  'MITHAQ',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.05),
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                  ),
                ),
              ),

              // Grid pattern overlay
              CustomPaint(
                size: const Size(double.infinity, 380),
                painter: GridPainter(),
              ),

              Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    // Verified Badge
                    if (isVerified)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: MithaqColors.mint.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: MithaqColors.mint.withValues(alpha: 0.5),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified_user,
                              color: MithaqColors.mint,
                              size: 16,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'موثق ومعتمد',
                              style: TextStyle(
                                color: MithaqColors.mint,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 32),

                    // Guardian Name Section
                    const _CardLabel(label: 'اسم ولي الأمر'),
                    const SizedBox(height: 8),
                    Text(
                      guardianName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 24),
                    const Divider(color: Colors.white12),
                    const SizedBox(height: 24),

                    // Kinship Section
                    const _CardLabel(label: 'صلة القرابة'),
                    const SizedBox(height: 8),
                    Text(
                      guardianTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 24),
                    const Divider(color: Colors.white12),
                    const SizedBox(height: 24),

                    // Phone Section
                    const _CardLabel(label: 'رقم التواصل المباشر'),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.phone_in_talk_rounded,
                          color: MithaqColors.mint,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          contactPhone,
                          textDirection: TextDirection.ltr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Footer Text
        Padding(
          padding: const EdgeInsets.all(40),
          child: Text(
            'هذه البطاقة رسمية وصادرة من تطبيق ميثاق، تُستخدم حصرياً لغرض التواصل الرسمي بين العائلات وفق الضوابط الشرعية.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 13,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }
}

class _CardLabel extends StatelessWidget {
  final String label;
  const _CardLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.4),
        fontSize: 12,
        letterSpacing: 0.5,
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..strokeWidth = 1;

    const spacing = 20.0;

    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < 500; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Full Screen Dialog to show the card
void showShufaCard(
  BuildContext context, {
  required String name,
  required String title,
  required String phone,
  bool isVerified = true,
}) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close',
    barrierColor: const Color(0xFF0D1117).withValues(alpha: 0.98),
    transitionDuration: const Duration(milliseconds: 400),
    pageBuilder: (context, _, __) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: ShufaCardWidget(
                guardianName: name,
                guardianTitle: title,
                contactPhone: phone,
                isVerified: isVerified,
              ),
            ),
          ),
        ),
      );
    },
    transitionBuilder: (context, anim1, anim2, child) {
      return FadeTransition(
        opacity: anim1,
        child: ScaleTransition(
          scale: anim1.drive(CurveTween(curve: Curves.easeOutBack)),
          child: child,
        ),
      );
    },
  );
}
