// lib/core/services/purchase_service.dart

import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'auth_service.dart';

class SubscriptionDetails {
  final String planType; // 'monthly', 'yearly', 'lifetime'
  final DateTime? expiryDate;
  
  SubscriptionDetails({required this.planType, this.expiryDate});
}

class PurchaseService {
  final AuthService _authService;
  
  PurchaseService(this._authService);
  
  // Ürünleri yükle
  Future<List<ProductDetails>> loadProducts() async {
    final bool isAvailable = await InAppPurchase.instance.isAvailable();
    if (!isAvailable) {
      return [];
    }
    
    const Set<String> productIds = {
      'com.zikirmo.monthly_subscription',
      'com.zikirmo.yearly_subscription',
      'com.zikirmo.lifetime_subscription',
    };
    
    final ProductDetailsResponse response = 
        await InAppPurchase.instance.queryProductDetails(productIds);
        
    return response.productDetails;
  }
  
  // Satın alma işlemi
  Future<bool> purchase(String planType) async {
    final products = await loadProducts();
    
    String targetId;
    switch (planType) {
      case 'monthly':
        targetId = 'com.zikirmo.monthly_subscription';
        break;
      case 'yearly':
        targetId = 'com.zikirmo.yearly_subscription';
        break;
      case 'lifetime':
        targetId = 'com.zikirmo.lifetime_subscription';
        break;
      default:
        return false;
    }
    
    final product = products.firstWhere(
      (p) => p.id == targetId,
      orElse: () => throw Exception('Ürün bulunamadı'),
    );
    
    final purchaseParam = PurchaseParam(productDetails: product);
    
    // Abonelik veya tek seferlik satın alma
    if (planType == 'lifetime') {
      await InAppPurchase.instance.buyNonConsumable(purchaseParam: purchaseParam);
    } else {
      await InAppPurchase.instance.buyConsumable(purchaseParam: purchaseParam);
    }
    
    return true;
  }
  
  // Mevcut abonelik detaylarını getir
  Future<SubscriptionDetails?> getSubscriptionDetails() async {
    final user = _authService.currentUser;
    if (user == null) return null;
    
    return SubscriptionDetails(
      planType: 'yearly', 
      expiryDate: DateTime.now().add(const Duration(days: 365))
    );
  }
}