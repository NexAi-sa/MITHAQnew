/// معرفات المنتجات للمشتريات داخل التطبيق (In-App Purchases)
/// تتوافق مع التكوين في Apple App Store Connect
/// RevenueCat Public API Key (iOS): appl_yErAfapxRJORVxlkvbjTQXseREP
class MithaqProductIds {
  // --- الاشتراكات (Subscriptions) ---
  // Subscription Group: Mithaq_Premium

  /// باقة المستكشف - شهر واحد
  static const String explorerMonthly = '001';

  /// باقة الجاد - 3 أشهر (الأكثر شيوعاً)
  static const String seriousQuarterly = '003';

  /// باقة النخبة - سنة كاملة
  static const String eliteYearly = '0012';

  // --- العناصر الاستهلاكية (Consumables) ---

  /// طلب شوفة / كشف الرقم (mithaq_unlock_contact)
  static const String revealContact = '0049';

  /// إضافة ملف تابع إضافي (mithaq_add_family_slot)
  static const String addProfile = '0099';

  /// قائمة بجميع معرفات الاشتراكات
  static const Set<String> subscriptionIds = {
    explorerMonthly,
    seriousQuarterly,
    eliteYearly,
  };

  /// قائمة بجميع معرفات العناصر الاستهلاكية
  static const Set<String> consumableIds = {revealContact, addProfile};

  /// كل المنتجات
  static const Set<String> allProductIds = {
    ...subscriptionIds,
    ...consumableIds,
  };
}
