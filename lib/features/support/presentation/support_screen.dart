import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/design_system.dart';
import '../../../core/ui/design_tokens.dart';
import '../../../core/ui/components/mithaq_card.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('الدعم والمساعدة'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: BackButton(color: Theme.of(context).colorScheme.primary),
      ),
      body: ListView(
        padding: EdgeInsets.all(MithaqSpacing.m),
        children: [
          // AI Support Agent Card
          MithaqCard(
            padding: EdgeInsets.all(MithaqSpacing.l),
            color: MithaqColors.mint.withValues(alpha: 0.1),
            child: Column(
              children: [
                const Icon(
                  Icons.smart_toy_rounded,
                  size: 64,
                  color: MithaqColors.mint,
                ),
                SizedBox(height: MithaqSpacing.m),
                const Text(
                  'وكيل الدعم الذكي',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: MithaqColors.navy,
                  ),
                ),
                SizedBox(height: MithaqSpacing.s),
                const Text(
                  'هل لديك استفسار عن السياسات أو تواجه مشكلة؟ وكيلنا الذكي مدرب للإجابة فوراً.',
                  textAlign: TextAlign.center,
                  style: TextStyle(height: 1.5, color: Colors.grey),
                ),
                SizedBox(height: MithaqSpacing.l),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      context.push(
                        Uri(
                          path: '/advisor',
                          queryParameters: {'profileId': 'support'},
                        ).toString(),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MithaqColors.navy,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('بدء المحادثة الآن'),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: MithaqSpacing.l),

          // Common Questions Section
          _buildSectionHeader(context, 'قنوات تواصل أخرى'),
          SizedBox(height: MithaqSpacing.s),
          MithaqCard(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.email_outlined, color: Colors.blue),
                  title: const Text('البريد الإلكتروني'),
                  subtitle: const Text('mithaqapp300@gmail.com'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // Implement email launch
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(
                    Icons.handshake_outlined,
                    color: MithaqColors.mint,
                  ),
                  title: const Text('تعرف على بروتوكول ميثاق'),
                  subtitle: const Text('آلية التواصل والخصوصية'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    context.push('/legal/terms');
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(
                    Icons.privacy_tip_outlined,
                    color: Colors.teal,
                  ),
                  title: const Text('سياسة الخصوصية'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    context.push('/legal/privacy');
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(
                    Icons.description_outlined,
                    color: Colors.orange,
                  ),
                  title: const Text('الشروط والأحكام'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    context.push('/legal/terms');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: MithaqSpacing.xs),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}
