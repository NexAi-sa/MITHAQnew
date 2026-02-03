import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/design_system.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/ui/design_tokens.dart';
import '../../../core/ui/components/mithaq_card.dart';
import '../../../core/session/session_provider.dart';
import '../../../core/session/app_session.dart';
import '../../seeker/data/profile_repository.dart';

/// Settings Screen - Clean and organized settings for Seeker users
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('الإعدادات'),
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
              context.go('/seeker/home');
            }
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(MithaqSpacing.m),
        children: [
          // Preferences Section
          _buildSectionHeader(context, 'التفضيلات'),
          const SizedBox(height: MithaqSpacing.s),
          _buildPreferencesSection(context, ref, themeMode),
          const SizedBox(height: MithaqSpacing.xl),

          // Privacy Section
          _buildSectionHeader(context, 'الخصوصية والشروط'),
          const SizedBox(height: MithaqSpacing.s),
          _buildPrivacySection(context),
          const SizedBox(height: MithaqSpacing.xl),

          // Support Section
          _buildSectionHeader(context, 'الدعم والمساعدة'),
          const SizedBox(height: MithaqSpacing.s),
          _buildSupportSection(context),
          const SizedBox(height: MithaqSpacing.xl),

          // Account Management Section
          _buildSectionHeader(context, 'إدارة الحساب'),
          const SizedBox(height: MithaqSpacing.s),
          _buildAccountManagementSection(context, ref, session),
          const SizedBox(height: MithaqSpacing.xl),

          // Developer Options (temporary)
          if (true) ...[
            _buildSectionHeader(context, 'خيارات المطور'),
            const SizedBox(height: MithaqSpacing.s),
            _buildDevSection(context, ref, session),
            const SizedBox(height: MithaqSpacing.xl),
          ],

          // App Info
          _buildAppInfo(),
          const SizedBox(height: MithaqSpacing.xxl),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final primaryColor = Theme.of(context).brightness == Brightness.light
        ? MithaqColors.navy
        : MithaqColors.textPrimaryDark;
    return Text(
      title,
      style: TextStyle(
        color: primaryColor.withValues(alpha: 0.6),
        fontSize: MithaqTypography.bodySmall,
        fontWeight: FontWeight.w600,
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
          // Language
          ListTile(
            leading: Icon(
              Icons.language,
              color: Theme.of(context).brightness == Brightness.light
                  ? MithaqColors.navy
                  : MithaqColors.mint,
            ),
            title: const Text('اللغة'),
            subtitle: const Text('العربية'),
            trailing: const Icon(Icons.chevron_left),
            onTap: () => _showLanguageDialog(context),
          ),
          const Divider(height: 1),
          // Theme
          ListTile(
            leading: Icon(
              Icons.palette_outlined,
              color: Theme.of(context).brightness == Brightness.light
                  ? MithaqColors.navy
                  : MithaqColors.mint,
            ),
            title: const Text('المظهر'),
            subtitle: Text(_getThemeLabel(themeMode)),
            trailing: const Icon(Icons.chevron_left),
            onTap: () => _showThemeDialog(context, ref, themeMode),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacySection(BuildContext context) {
    return MithaqCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              Icons.privacy_tip_outlined,
              color: Theme.of(context).brightness == Brightness.light
                  ? MithaqColors.navy
                  : MithaqColors.mint,
            ),
            title: const Text('سياسة الخصوصية'),
            trailing: const Icon(Icons.chevron_left),
            onTap: () => context.push('/legal/privacy'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(
              Icons.description_outlined,
              color: Theme.of(context).brightness == Brightness.light
                  ? MithaqColors.navy
                  : MithaqColors.mint,
            ),
            title: const Text('شروط الاستخدام'),
            trailing: const Icon(Icons.chevron_left),
            onTap: () => context.push('/legal/terms'),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportSection(BuildContext context) {
    return MithaqCard(
      padding: EdgeInsets.zero,
      child: ListTile(
        leading: const Icon(Icons.support_agent, color: MithaqColors.mint),
        title: const Text('الدعم الفني'),
        subtitle: const Text('دعم فني ذكي متاح على مدار الساعة'),
        trailing: const Icon(Icons.chevron_left),
        onTap: () => context.push('/support'),
      ),
    );
  }

  Widget _buildAccountManagementSection(
    BuildContext context,
    WidgetRef ref,
    AppSession session,
  ) {
    return MithaqCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Pause Account
          ListTile(
            leading: Icon(
              session.isPaused
                  ? Icons.play_circle_outline
                  : Icons.pause_circle_outline,
              color: MithaqColors.navy,
            ),
            title: Text(
              session.isPaused ? 'إلغاء تجميد الحساب' : 'تجميد الحساب',
            ),
            subtitle: Text(
              session.isPaused
                  ? 'حسابك مخفي حالياً'
                  : 'إخفاء ملفك من البحث مؤقتاً',
            ),
            trailing: Switch(
              value: session.isPaused,
              activeThumbColor: MithaqColors.mint,
              onChanged: (val) => _showPauseDialog(context, ref, val),
            ),
          ),
          const Divider(height: 1),
          // Delete Account
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text(
              'حذف الحساب',
              style: TextStyle(color: Colors.red),
            ),
            subtitle: Text(
              'إزالة حسابك نهائياً',
              style: TextStyle(color: Colors.red.withValues(alpha: 0.7)),
            ),
            trailing: const Icon(Icons.chevron_left, color: Colors.red),
            onTap: () => context.push('/seeker/account/delete'),
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
          // Session Info
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
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.orange),
            title: const Text('تسجيل الخروج'),
            onTap: () async {
              await notifier.setAuthSignedOut();
              if (context.mounted) context.go('/auth');
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.refresh, color: Colors.red),
            title: const Text(
              'إعادة ضبط الجلسة',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () async {
              await notifier.resetSessionSafely();
              if (context.mounted) context.go('/');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAppInfo() {
    return Center(
      child: Column(
        children: [
          Text(
            'ميثاق',
            style: TextStyle(
              color: MithaqColors.navy.withValues(alpha: 0.5),
              fontSize: MithaqTypography.bodyMedium,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'الإصدار 1.0.0',
            style: TextStyle(
              color: MithaqColors.navy.withValues(alpha: 0.3),
              fontSize: MithaqTypography.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  String _getThemeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'فاتح';
      case ThemeMode.dark:
        return 'داكن';
      case ThemeMode.system:
        return 'تلقائي (النظام)';
    }
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('اختر اللغة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('العربية'),
              trailing: const Icon(Icons.check, color: MithaqColors.mint),
              onTap: () => Navigator.pop(ctx),
            ),
            const ListTile(
              title: Text('English'),
              enabled: false,
              subtitle: Text('قريباً'),
            ),
          ],
        ),
      ),
    );
  }

  void _showThemeDialog(
    BuildContext context,
    WidgetRef ref,
    ThemeMode current,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('اختر المظهر'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              value: ThemeMode.light,
              groupValue: current,
              title: const Text('فاتح'),
              activeColor: MithaqColors.mint,
              onChanged: (val) {
                ref
                    .read(themeModeProvider.notifier)
                    .setThemeMode(ThemeMode.light);
                Navigator.pop(ctx);
              },
            ),
            RadioListTile<ThemeMode>(
              value: ThemeMode.dark,
              groupValue: current,
              title: const Text('داكن'),
              activeColor: MithaqColors.mint,
              onChanged: (val) {
                ref
                    .read(themeModeProvider.notifier)
                    .setThemeMode(ThemeMode.dark);
                Navigator.pop(ctx);
              },
            ),
            RadioListTile<ThemeMode>(
              value: ThemeMode.system,
              groupValue: current,
              title: const Text('تلقائي (النظام)'),
              activeColor: MithaqColors.mint,
              onChanged: (val) {
                ref
                    .read(themeModeProvider.notifier)
                    .setThemeMode(ThemeMode.system);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showPauseDialog(BuildContext context, WidgetRef ref, bool pause) {
    bool isLoading = false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(pause ? 'تجميد الحساب' : 'إلغاء التجميد'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  pause
                      ? 'لن يظهر حسابك للآخرين. يمكنك العودة في أي وقت.'
                      : 'سيتم إعادة تفعيل حسابك ليظهر للآخرين.',
                ),
                if (isLoading)
                  const Padding(
                    padding: EdgeInsets.only(top: MithaqSpacing.m),
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Navigator.pop(ctx),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        setState(() => isLoading = true);
                        try {
                          final repository = ref.read(
                            profileRepositoryProvider,
                          );
                          final session = ref.read(sessionProvider);

                          // Use profileId if available, fall back to userId
                          final idToUse = session.profileId ?? session.userId;

                          if (idToUse != null) {
                            await repository.togglePause(idToUse);
                            await ref
                                .read(sessionProvider.notifier)
                                .togglePaused();

                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    pause
                                        ? 'تم تجميد الحساب'
                                        : 'تم تفعيل الحساب',
                                  ),
                                  backgroundColor: MithaqColors.mint,
                                ),
                              );
                            }
                          } else {
                            throw Exception('No profile ID found');
                          }
                        } catch (e) {
                          if (ctx.mounted) {
                            setState(() => isLoading = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'حدث خطأ أثناء العملية، حاول مرة أخرى',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                            Navigator.pop(ctx);
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: MithaqColors.navy,
                  foregroundColor: Colors.white,
                ),
                child: Text(pause ? 'تجميد' : 'تفعيل'),
              ),
            ],
          );
        },
      ),
    );
  }
}
