import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/ui/design_tokens.dart';
import '../../../core/ui/components/mithaq_card.dart';
import '../../../core/session/session_provider.dart';
import '../../../core/session/app_session.dart';

class GuardianSettingsScreen extends ConsumerWidget {
  const GuardianSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We can reuse most logic, just different navigation paths
    final session = ref.watch(sessionProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('الإعدادات (ولي الأمر)'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.primary,
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/guardian/dashboard');
            }
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(MithaqSpacing.m),
        children: [
          // Preferences
          _buildSectionHeader(context, 'التفضيلات'),
          const SizedBox(height: MithaqSpacing.s),
          _buildPreferencesSection(context, ref, themeMode),
          const SizedBox(height: MithaqSpacing.xl),

          // Info & Support
          _buildSectionHeader(context, 'معلومات التطبيق والدعم'),
          const SizedBox(height: MithaqSpacing.s),
          _buildInfoSection(context),
          const SizedBox(height: MithaqSpacing.xl),

          // Account (Logout, etc)
          _buildSectionHeader(context, 'إدارة الحساب'),
          const SizedBox(height: MithaqSpacing.s),
          _buildAccountManagementSection(context, ref, session),
          const SizedBox(height: MithaqSpacing.xl),

          // Dev Options
          if (true) ...[
            _buildSectionHeader(context, 'خيارات المطور'),
            const SizedBox(height: MithaqSpacing.s),
            _buildDevSection(context, ref, session),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    return MithaqCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('الدعم الفني'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => context.push('/support'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('شروط الاستخدام'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => context.push('/legal/terms'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('سياسة الخصوصية'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => context.push('/legal/privacy'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildPreferencesSection(
    BuildContext context,
    WidgetRef ref,
    ThemeMode themeMode,
  ) {
    return MithaqCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('اللغة'),
            subtitle: const Text('العربية'),
            onTap: () {},
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('المظهر'),
            subtitle: Text(themeMode == ThemeMode.dark ? 'داكن' : 'فاتح'),
            onTap: () {
              final newMode = themeMode == ThemeMode.dark
                  ? ThemeMode.light
                  : ThemeMode.dark;
              ref.read(themeModeProvider.notifier).setThemeMode(newMode);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAccountManagementSection(
    BuildContext context,
    WidgetRef ref,
    AppSession session,
  ) {
    final notifier = ref.read(sessionProvider.notifier);
    return MithaqCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.orange),
            title: const Text('تسجيل الخروج'),
            onTap: () async {
              await notifier.setAuthSignedOut();
              if (context.mounted) context.go('/auth');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDevSection(
    BuildContext context,
    WidgetRef ref,
    AppSession session,
  ) {
    final notifier = ref.read(sessionProvider.notifier);

    return MithaqCard(
      padding: EdgeInsets.zero,
      color: Colors.amber.withValues(alpha: 0.1),
      child: Column(
        children: [
          ListTile(
            dense: true,
            title: Text(
              'الدور: ${session.role.name} | الملف: ${session.profileStatus.name}',
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.swap_horiz),
            title: const Text('تبديل الدور'),
            onTap: () async {
              final newRole = session.role == UserRole.seeker
                  ? UserRole.guardian
                  : UserRole.seeker;
              await notifier.setRole(newRole);
              if (context.mounted) context.go('/');
            },
          ),
        ],
      ),
    );
  }
}
