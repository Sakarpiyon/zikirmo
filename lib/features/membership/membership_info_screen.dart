// Dosya: lib/features/membership/membership_info_screen.dart
// Açıklama: Freemium ve premium üyelik özelliklerini ve fiyatlarını tanıtan ekranı tanımlar.
// Klasör: lib/features/membership

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:zikirmo_new/core/services/firestore_service.dart';

class MembershipInfoScreen extends StatelessWidget {
  const MembershipInfoScreen({super.key});

  String _getPriceByRegion(BuildContext context) {
    // Bölgeye göre fiyat belirleme (ülke kodu easy_localization ile alınır)
    final locale = context.locale.countryCode ?? 'US';
    if (locale == 'TR') {
      return '29 TL/ay';
    } else if (['AT', 'BE', 'BG', 'HR', 'CY', 'CZ', 'DK', 'EE', 'FI', 'FR', 'DE', 'GR', 'HU', 'IE', 'IT', 'LV', 'LT', 'LU', 'MT', 'NL', 'PL', 'PT', 'RO', 'SK', 'SI', 'ES', 'SE'].contains(locale)) {
      return '0.99 EUR/ay';
    } else {
      return '0.99 USD/ay';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('membershipInfoTitle'.tr()),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'membershipInfoHeader'.tr(),
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              // Freemium Kartı
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'freemiumTitle'.tr(),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 10),
                      Text('freemiumDescription'.tr()),
                      const SizedBox(height: 10),
                      Text('freemiumFeatures'.tr()),
                      const SizedBox(height: 10),
                      Text(
                        'freemiumPrice'.tr(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Premium Kartı
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'premiumTitle'.tr(),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 10),
                      Text('premiumDescription'.tr()),
                      const SizedBox(height: 10),
                      Text('premiumFeatures'.tr()),
                      const SizedBox(height: 10),
                      Text(
                        'premiumPrice'.tr(args: [_getPriceByRegion(context)]),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/login');
                  },
                  child: Text('getStarted'.tr()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Dosya Sonu: lib/features/membership/membership_info_screen.dart