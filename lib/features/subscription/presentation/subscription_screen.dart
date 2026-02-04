import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/design_system.dart';
import '../../../core/ui/design_tokens.dart';
import '../data/subscription_service.dart';

// Gold color constant
const kGoldColor = Color(0xFFD4AF37);

/// Subscription Screen with Real RevenueCat Integration
class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offeringsAsync = ref.watch(offeringsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'باقات ميثاق',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: offeringsAsync.when(
        data: (offerings) {
          if (offerings == null || offerings.current == null) {
            return _buildErrorState(context, ref, 'لا توجد باقات متاحة حالياً');
          }
          return _buildOfferingsUI(context, ref, offerings.current!);
        },
        loading: () => _buildLoadingState(),
        error: (error, stack) =>
            _buildErrorState(context, ref, 'حدث خطأ في تحميل الباقات'),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: MithaqColors.mint),
          SizedBox(height: 16),
          Text('جاري تحميل الباقات...'),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, String message) {
    // Check if error message indicates configuration issue
    final isConfigError =
        message.contains('CONFIGURATION_ERROR') || message.contains('23');

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(MithaqSpacing.l),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isConfigError
                  ? Icons.settings_suggest_outlined
                  : Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              isConfigError
                  ? 'عذراً، نظام المدفوعات تحت الصيانة أو لم يتم تفعيله بعد في متجر التطبيقات.'
                  : message,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            if (isConfigError) ...[
              const SizedBox(height: 8),
              const Text(
                'تأكد من قبول "اتفاقية التطبيقات المدفوعة" في حساب المطور الخاص بك.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => ref.refresh(offeringsProvider),
              style: ElevatedButton.styleFrom(
                backgroundColor: MithaqColors.mint,
                foregroundColor: MithaqColors.navy,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfferingsUI(
    BuildContext context,
    WidgetRef ref,
    Offering offering,
  ) {
    final packages = offering.availablePackages;
    final monthly = packages
        .where((p) => p.packageType == PackageType.monthly)
        .firstOrNull;
    final threeMonth = packages
        .where((p) => p.packageType == PackageType.threeMonth)
        .firstOrNull;
    final annual = packages
        .where((p) => p.packageType == PackageType.annual)
        .firstOrNull;

    final sortedPackages = [
      if (monthly != null) monthly,
      if (threeMonth != null) threeMonth,
      if (annual != null) annual,
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(MithaqSpacing.m),
      child: Column(
        children: [
          const _HeroHeader(),
          const SizedBox(height: MithaqSpacing.l),
          ...sortedPackages.map(
            (package) => Padding(
              padding: const EdgeInsets.only(bottom: MithaqSpacing.m),
              child: _SubscriptionCard(
                package: package,
                onTap: () => _handlePurchase(context, ref, package),
              ),
            ),
          ),
          const SizedBox(height: MithaqSpacing.xxl),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () => _handleRestore(context, ref),
                child: const Text(
                  'استعادة المشتريات',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ],
          ),
          const _LegalFooter(),
        ],
      ),
    );
  }

  Future<void> _handlePurchase(
    BuildContext context,
    WidgetRef ref,
    Package package,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: MithaqColors.mint),
      ),
    );

    try {
      final service = ref.read(subscriptionServiceProvider);
      final success = await service.purchasePackage(package);

      if (context.mounted) {
        Navigator.pop(context);
        if (success) {
          _showSuccessDialog(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم إلغاء عملية الشراء'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleRestore(BuildContext context, WidgetRef ref) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: MithaqColors.mint),
      ),
    );

    try {
      final service = ref.read(subscriptionServiceProvider);
      final customerInfo = await service.restorePurchases();

      if (context.mounted) {
        Navigator.pop(context);
        if (customerInfo != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ تم استعادة المشتريات بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('لا توجد مشتريات سابقة'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: MithaqColors.mint.withValues(alpha: 0.15),
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 48,
                color: MithaqColors.mint,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'مبروك! 🎉',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: MithaqColors.navy,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'تم تفعيل اشتراكك بنجاح',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 15),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MithaqColors.mint,
                  foregroundColor: MithaqColors.navy,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('رائع!'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(
          Icons.workspace_premium_rounded,
          size: 64,
          color: kGoldColor,
        ),
        const SizedBox(height: MithaqSpacing.s),
        Text(
          'استثمر في مستقبلك',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: MithaqColors.navy,
          ),
        ),
        const SizedBox(height: MithaqSpacing.xs),
        Text(
          'اختر الباقة المناسبة لرحلة البحث عن شريك حياتك',
          style: TextStyle(
            color: MithaqColors.navy.withValues(alpha: 0.6),
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  final Package package;
  final VoidCallback onTap;

  const _SubscriptionCard({required this.package, required this.onTap});

  String get _packageTitle {
    switch (package.packageType) {
      case PackageType.monthly:
        return 'المستكشف';
      case PackageType.threeMonth:
        return 'الجاد';
      case PackageType.annual:
        return 'النخبة';
      default:
        return package.storeProduct.title;
    }
  }

  String get _packageSubtitle {
    switch (package.packageType) {
      case PackageType.monthly:
        return 'The Explorer';
      case PackageType.threeMonth:
        return 'The Serious';
      case PackageType.annual:
        return 'The Elite';
      default:
        return '';
    }
  }

  String get _duration {
    switch (package.packageType) {
      case PackageType.monthly:
        return 'شهرياً';
      case PackageType.threeMonth:
        return '3 أشهر';
      case PackageType.annual:
        return 'سنة كاملة';
      default:
        return '';
    }
  }

  List<String> get _features {
    switch (package.packageType) {
      case PackageType.monthly:
        return [
          'تصفح الملفات الأساسية',
          'إرسال عدد محدود من الاستفسارات',
          'الوصول لجميع الميزات الأساسية',
        ];
      case PackageType.threeMonth:
        return [
          'توفير 40% مقارنة بالشهري',
          'أولوية في ظهور الملف',
          'دعم فني مباشر',
          'شارة "الجاد" المميزة',
        ];
      case PackageType.annual:
        return [
          'أقصى توفير - أقل من 75 ر.س شهرياً',
          'شارة "النخبة" المميزة',
          'وصول كامل لجميع الميزات',
          'استشارات مجانية مع مستشار أسري',
          'مناسب للعائلات - عدد لا محدود من الملفات',
          'رؤية غير محدودة للملفات',
        ];
      default:
        return [];
    }
  }

  bool get _isPopular => package.packageType == PackageType.threeMonth;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MithaqRadius.m),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(MithaqRadius.m),
              border: _isPopular
                  ? Border.all(color: kGoldColor, width: 2)
                  : null,
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(MithaqSpacing.m),
                  decoration: BoxDecoration(
                    color: _isPopular
                        ? kGoldColor.withValues(alpha: 0.1)
                        : Colors.grey[50],
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(MithaqRadius.m),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _packageTitle,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _isPopular
                                  ? MithaqColors.navy
                                  : Colors.black87,
                            ),
                          ),
                          Text(
                            _packageSubtitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: MithaqColors.navy.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            package.storeProduct.priceString,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: MithaqColors.navy,
                            ),
                          ),
                          Text(
                            ' / $_duration',
                            style: TextStyle(
                              fontSize: 12,
                              color: MithaqColors.navy.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(MithaqSpacing.m),
                  child: Column(
                    children: [
                      ..._features.map(
                        (f) => Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 16,
                                color: _isPopular ? kGoldColor : Colors.green,
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: Text(f)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: MithaqSpacing.m),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: onTap,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isPopular
                                ? kGoldColor
                                : MithaqColors.navy,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'اشتراك الآن',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _isPopular
                                  ? MithaqColors.navy
                                  : Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_isPopular)
          Positioned(
            top: -10,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: kGoldColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Text(
                'الأكثر مبيعاً',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _LegalFooter extends StatelessWidget {
  const _LegalFooter();

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(fontSize: 11, color: Colors.grey);
    return Column(
      children: [
        const SizedBox(height: 8),
        const Text(
          'سيتم تجديد الاشتراك تلقائياً ما لم يتم إلغاؤه قبل 24 ساعة من نهاية الفترة الحالية.',
          style: style,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () => context.push('/legal/terms'),
              child: const Text('شروط الاستخدام', style: style),
            ),
            const Text('|', style: style),
            TextButton(
              onPressed: () => context.push('/legal/privacy'),
              child: const Text('سياسة الخصوصية', style: style),
            ),
          ],
        ),
      ],
    );
  }
}
