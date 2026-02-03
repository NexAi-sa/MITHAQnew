import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class SubscriptionService {
  // API Keys
  static const String _apiKeyApple = 'appl_yErAfapxRJORVxlkvbjTQXseREP';
  // static const String _apiKeyGoogle = 'YOUR_GOOGLE_KEY_HERE';

  // Entitlement ID configured in RevenueCat
  static const String _entitlementId = 'premium';

  Future<void> init() async {
    try {
      await Purchases.setLogLevel(LogLevel.debug);

      PurchasesConfiguration? configuration;

      if (Platform.isIOS) {
        configuration = PurchasesConfiguration(_apiKeyApple);
      } else if (Platform.isAndroid) {
        // configuration = PurchasesConfiguration(_apiKeyGoogle);
      }

      if (configuration != null) {
        await Purchases.configure(configuration);
      }
      print('✅ RevenueCat initialized successfully');
    } catch (e) {
      print('⚠️ RevenueCat initialization failed: $e');
      print('ℹ️ The app will continue without in-app purchases');
      // Don't throw - allow app to continue without purchases
    }
  }

  /// Get current offerings (Paywalls)
  Future<Offerings?> getOfferings() async {
    try {
      final offerings = await Purchases.getOfferings();
      return offerings;
    } on PlatformException catch (e) {
      print('Error fetching offerings: $e');
      return null;
    }
  }

  /// Fetch a specific product by ID
  Future<StoreProduct?> getProduct(String productIdentifier) async {
    try {
      final products = await Purchases.getProducts([productIdentifier]);
      if (products.isNotEmpty) {
        return products.first;
      }
      return null;
    } on PlatformException catch (e) {
      print('Error fetching product $productIdentifier: $e');
      return null;
    }
  }

  /// Purchase a package (Subscription)
  /// Returns true if purchase was successful
  Future<bool> purchasePackage(Package package) async {
    try {
      await Purchases.purchasePackage(package);
      return true;
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode != PurchasesErrorCode.purchaseCancelledError) {
        print('Purchase error: $e');
      }
      return false;
    }
  }

  /// Purchase a product (Consumable)
  /// Returns true if purchase was successful
  Future<bool> purchaseProduct(StoreProduct product) async {
    try {
      await Purchases.purchaseStoreProduct(product);
      return true;
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode != PurchasesErrorCode.purchaseCancelledError) {
        print('Consumable purchase error: $e');
      }
      return false;
    }
  }

  /// Restore purchases
  Future<CustomerInfo?> restorePurchases() async {
    try {
      final customerInfo = await Purchases.restorePurchases();
      return customerInfo;
    } on PlatformException catch (e) {
      print('Restore error: $e');
      return null;
    }
  }

  /// Check if user has active entitlement
  Future<bool> isProUser() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.all[_entitlementId]?.isActive ?? false;
    } on PlatformException catch (e) {
      print('Check status error: $e');
      return false;
    }
  }
}

final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  return SubscriptionService();
});

// FutureProvider for easier UI consumption
final offeringsProvider = FutureProvider<Offerings?>((ref) async {
  final service = ref.watch(subscriptionServiceProvider);
  return service.getOfferings();
});
