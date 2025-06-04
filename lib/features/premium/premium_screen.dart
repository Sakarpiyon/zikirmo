// lib/features/premium/premium_screen.dart

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/providers.dart'; // Sadece bu import

class PremiumScreen extends ConsumerStatefulWidget {
  const PremiumScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends ConsumerState<PremiumScreen> {
  bool _isLoading = true;
  String _selectedPlan = 'yearly'; // Varsayılan plan
  final Map<String, double> _planPrices = {
    'monthly': 9.99,  // Düzeltildi - double değer
    'yearly': 49.99,  // Düzeltildi - double değer
    'lifetime': 99.99, // Düzeltildi - double değer
  };
  bool _isPremium = false;
  String? _currentPlan;
  DateTime? _expiryDate;
  
  @override
  void initState() {
    super.initState();
    _loadSubscriptionStatus();
  }
  
  Future<void> _loadSubscriptionStatus() async {
    try {
      final purchaseService = ref.read(purchaseServiceProvider);
      final products = await purchaseService.loadProducts();
      
      // Güncel fiyatları al
      if (products.isNotEmpty) {
        // Ürün fiyatlarını güncelle
        for (var product in products) {
          if (product.id.contains('monthly')) {
            _planPrices['monthly'] = double.tryParse(product.price) ?? 9.99;
          } else if (product.id.contains('yearly')) {
            _planPrices['yearly'] = double.tryParse(product.price) ?? 49.99;
          } else if (product.id.contains('lifetime')) {
            _planPrices['lifetime'] = double.tryParse(product.price) ?? 99.99;
          }
        }
      }
      
      // Mevcut abonelik durumunu kontrol et
      final authService = ref.read(authServiceProvider);
      _isPremium = await authService.checkIfUserIsPremium();
      
      if (_isPremium) {
        final subscriptionDetails = await purchaseService.getSubscriptionDetails();
        _currentPlan = subscriptionDetails?.planType;
        _expiryDate = subscriptionDetails?.expiryDate;
      }
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('errorLoadingProducts'.tr())),
        );
      }
    }
  }
  
  Future<void> _startPurchase() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final purchaseService = ref.read(purchaseServiceProvider);
      final success = await purchaseService.purchase(_selectedPlan);
      
      if (success && mounted) {
        // Başarılı satın alma
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('purchaseSuccessful'.tr())),
        );
        
        // Durumu güncelle
        await _loadSubscriptionStatus();
      } else if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('purchaseError'.tr())),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('premiumMembership'.tr()),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Premium durum bilgisi
                  if (_isPremium) _buildCurrentSubscription(),
                  
                  // Premium özelliklerin listesi
                  _buildPremiumFeatures(),
                  
                  // Premium değilse abonelik seçenekleri
                  if (!_isPremium) _buildPlanOptions(),
                  
                  // Satın alma butonu
                  if (!_isPremium) _buildPurchaseButton(),
                  
                  const SizedBox(height: 24),
                  
                  // Hükümler ve koşullar
                  Text(
                    'termsAndPrivacy'.tr(),
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
    );
  }
  
  Widget _buildCurrentSubscription() {
    String statusText = 'currentlyPremium'.tr();
    if (_currentPlan != null) {
      statusText += ' - $_currentPlan';
    }
    
    if (_expiryDate != null && _currentPlan != 'lifetime') {
      final formattedDate = DateFormat.yMMMd(context.locale.languageCode).format(_expiryDate!);
      statusText += ' (${'validUntil'.tr(args: [formattedDate])})';
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 24),
      color: Colors.green[100],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.stars, color: Colors.green, size: 36),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    statusText,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (_currentPlan != 'lifetime' && _expiryDate != null)
              TextButton(
                onPressed: () => _startPurchase(),
                child: Text('renewSubscription'.tr()),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPremiumFeatures() {
    final features = [
      {'icon': Icons.format_size, 'title': 'customCounterSize'.tr()},
      {'icon': Icons.touch_app, 'title': 'wholeScreenCounter'.tr()},
      {'icon': Icons.visibility_off, 'title': 'minimalMode'.tr()},
      {'icon': Icons.drag_indicator, 'title': 'moveCounter'.tr()},
      {'icon': Icons.bar_chart, 'title': 'advancedStatistics'.tr()},
      {'icon': Icons.cloud_upload, 'title': 'cloudBackup'.tr()},
    ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'premiumFeatures'.tr(),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        ...features.map((feature) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Icon(feature['icon'] as IconData, color: Theme.of(context).primaryColor),
              const SizedBox(width: 12),
              Expanded(child: Text(feature['title'] as String)),
            ],
          ),
        )).toList(),
        const SizedBox(height: 24),
      ],
    );
  }
  
  Widget _buildPlanOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'choosePlan'.tr(),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildPlanCard(
                'monthly',
                'monthlyPlan'.tr(),
                '${_planPrices['monthly']!.toStringAsFixed(2)} ₺',
                'perMonth'.tr(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildPlanCard(
                'yearly',
                'yearlyPlan'.tr(),
                '${_planPrices['yearly']!.toStringAsFixed(2)} ₺',
                'perYear'.tr(),
                isRecommended: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildPlanCard(
                'lifetime',
                'lifetimePlan'.tr(),
                '${_planPrices['lifetime']!.toStringAsFixed(2)} ₺',
                'oneTime'.tr(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }
  
  Widget _buildPlanCard(String planId, String title, String price, String subtitle, {bool isRecommended = false}) {
    final isSelected = _selectedPlan == planId;
    
    return InkWell(
      onTap: () {
        setState(() {
          _selectedPlan = planId;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey[300]!,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? Colors.grey[50] : Colors.white,
        ),
        child: Column(
          children: [
            if (isRecommended)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'bestValue'.tr(),
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              price,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPurchaseButton() {
    return ElevatedButton(
      onPressed: _startPurchase,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text('upgradeToPremium'.tr()),
    );
  }
}