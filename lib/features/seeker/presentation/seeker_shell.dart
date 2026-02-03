import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/design_system.dart';
import '../../../core/ui/design_tokens.dart';

import '../../../core/ui/components/tutorial_overlay.dart';

/// The main shell for Seeker users with bottom navigation.
/// Contains 4 tabs: Discover, Messages, Account, Settings
class SeekerShell extends StatefulWidget {
  final Widget child;
  final String currentPath;

  const SeekerShell({
    super.key,
    required this.child,
    required this.currentPath,
  });

  @override
  State<SeekerShell> createState() => _SeekerShellState();
}

class _SeekerShellState extends State<SeekerShell> {
  int _currentIndex = 0;

  static const List<_NavItem> _navItems = [
    _NavItem(
      path: '/seeker/home',
      icon: Icons.explore_outlined,
      activeIcon: Icons.explore,
      label: 'اكتشف',
    ),
    _NavItem(
      path: '/seeker/messages',
      icon: Icons.chat_bubble_outline_rounded,
      activeIcon: Icons.chat_bubble_rounded,
      label: 'الرسائل',
    ),
    _NavItem(
      path: '/seeker/account',
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'حسابي',
    ),
    _NavItem(
      path: '/seeker/settings',
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings,
      label: 'الإعدادات',
    ),
  ];

  @override
  void didUpdateWidget(SeekerShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateIndexFromPath();
  }

  @override
  void initState() {
    super.initState();
    _updateIndexFromPath();
  }

  void _updateIndexFromPath() {
    final index = _navItems.indexWhere(
      (item) => widget.currentPath.startsWith(item.path),
    );
    if (index != -1 && index != _currentIndex) {
      setState(() => _currentIndex = index);
    }
  }

  void _onItemTapped(int index) {
    if (index == _currentIndex) return;

    HapticFeedback.selectionClick();
    setState(() => _currentIndex = index);
    context.go(_navItems[index].path);
  }

  final List<TutorialStep> _tourSteps = [
    TutorialStep(
      title: 'مرحباً بك في ميثاق',
      description: 'ابدأ رحلة البحث عن شريك حياتك بخصوصية تامة',
      alignment: Alignment.center,
    ),
    TutorialStep(
      title: 'اكتشف',
      description: 'تصفح الملفات المتوافقة معك وتعرف على التفاصيل العامة.',
      alignment: Alignment.bottomRight,
    ),
    TutorialStep(
      title: 'حسابي',
      description: 'أكمل بياناتك الشخصية وتفضيلاتك لزيادة فرص المطابقة.',
      alignment: Alignment.bottomCenter,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return TutorialOverlay(
      tourId: 'seeker_main_tour_v1',
      steps: _tourSteps,
      child: Scaffold(
        body: widget.child,
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: MithaqColors.navy.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: MithaqSpacing.s,
                vertical: MithaqSpacing.xs,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(
                  _navItems.length,
                  (index) => _buildNavItem(index),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final item = _navItems[index];
    final isSelected = index == _currentIndex;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: MithaqDurations.fast,
        padding: const EdgeInsets.symmetric(
          horizontal: MithaqSpacing.m,
          vertical: MithaqSpacing.s,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? MithaqColors.navy.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(MithaqRadius.m),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? item.activeIcon : item.icon,
              color: isSelected
                  ? MithaqColors.navy
                  : MithaqColors.navy.withValues(alpha: 0.5),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: TextStyle(
                color: isSelected
                    ? MithaqColors.navy
                    : MithaqColors.navy.withValues(alpha: 0.5),
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final String path;
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({
    required this.path,
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
