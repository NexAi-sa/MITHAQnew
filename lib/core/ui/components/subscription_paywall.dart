import 'package:flutter/material.dart';
import '../../theme/design_system.dart';

class SubscriptionPaywall extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onSubscribe;

  const SubscriptionPaywall({
    super.key,
    this.title = 'محتوى حصري للمشتركين',
    this.message =
        'لتصفح ملفات الأعضاء والتواصل معهم، يرجى تفعيل باقة الاشتراك.',
    this.onSubscribe,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: MithaqColors.mint.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                size: 64,
                color: MithaqColors.mint,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: MithaqColors.navy,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed:
                    onSubscribe ??
                    () {
                      // Mock subscription action
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('سيتم توجيهك لصفحة الدفع...'),
                        ),
                      );
                    },
                style: ElevatedButton.styleFrom(
                  backgroundColor: MithaqColors.navy,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'تفعيل الاشتراك الآن',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
