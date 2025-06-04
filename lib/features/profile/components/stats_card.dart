// Dosya: lib/features/profile/components/stats_card.dart
// Yol: C:\src\zikirmo_new\lib\features\profile\components\stats_card.dart

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/models/user_model.dart';

class StatsCard extends StatelessWidget {
  final UserModel user;
  
  const StatsCard({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'statistics'.tr(),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            // İstatistik kutucukları - 2x2 grid
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.2,
              children: [
                _buildStatCard(
                  context, 
                  Icons.touch_app,
                  'totalZikirs'.tr(),
                  user.totalZikirCount.toString(),
                  Colors.blue,
                ),
                _buildStatCard(
                  context, 
                  Icons.whatshot,
                  'currentStreak'.tr(),
                  '${user.currentStreak} ' + 'days'.tr(),
                  Colors.orange,
                ),
                _buildStatCard(
                  context, 
                  Icons.people,
                  'friends'.tr(),
                  user.friends.length.toString(),
                  Colors.green,
                ),
                _buildStatCard(
                  context, 
                  Icons.emoji_events,
                  'badges'.tr(),
                  user.badges.length.toString(),
                  Colors.purple,
                ),
              ],
            ),
            
            // Detaylı istatistikler butonu
            const SizedBox(height: 16),
            Center(
              child: TextButton.icon(
                onPressed: () {
                  // TODO: Ayrıntılı istatistik sayfasına git
                },
                icon: const Icon(Icons.bar_chart),
                label: Text('detailedStats'.tr()),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // İstatistik kutusu widget'ı
  Widget _buildStatCard(
    BuildContext context, 
    IconData icon, 
    String title, 
    String value,
    Color color,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 28, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}