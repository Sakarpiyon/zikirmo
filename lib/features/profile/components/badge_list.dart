// Dosya: lib/features/profile/components/badge_list.dart
// Yol: C:\src\zikirmo_new\lib\features\profile\components\badge_list.dart

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class BadgeList extends StatelessWidget {
  final List<String> badges;
  
  const BadgeList({
    Key? key,
    required this.badges,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'badges'.tr(),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (badges.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      // TODO: Tüm rozetler sayfasına git
                    },
                    child: Text('viewAll'.tr()),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (badges.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.emoji_events_outlined,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'noBadges'.tr(),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'earnBadgesByDoingZikir'.tr(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: badges.length > 5 ? 5 : badges.length,
                  itemBuilder: (context, index) {
                    return _buildBadge(context, badges[index]);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  // Rozet widget'ı
  Widget _buildBadge(BuildContext context, String badgeId) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: _getBadgeColor(badgeId).withOpacity(0.2),
            radius: 30,
            child: Icon(
              _getBadgeIcon(badgeId),
              color: _getBadgeColor(badgeId),
              size: 30,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 80,
            child: Text(
              _getBadgeName(badgeId),
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
  
  // Rozet adını getir
  String _getBadgeName(String badgeId) {
    switch (badgeId) {
      case 'badgeFirstZikir':
        return 'firstZikir'.tr();
      case 'badgeStreak7Days':
        return 'streak7Days'.tr();
      case 'badgeDailyPeak':
        return 'dailyPeak'.tr();
      case 'badgeZikir1000':
        return 'zikir1000'.tr();
      case 'badgeSocialShare':
        return 'socialShare'.tr();
      case 'badgeCreativeZikir':
        return 'creativeZikir'.tr();
      case 'badgePerfectWeek':
        return 'perfectWeek'.tr();
      default:
        return 'badge'.tr();
    }
  }
  
  // Rozet ikonu
  IconData _getBadgeIcon(String badgeId) {
    switch (badgeId) {
      case 'badgeFirstZikir':
        return Icons.star;
      case 'badgeStreak7Days':
        return Icons.whatshot;
      case 'badgeDailyPeak':
        return Icons.trending_up;
      case 'badgeZikir1000':
        return Icons.emoji_events;
      case 'badgeSocialShare':
        return Icons.share;
      case 'badgeCreativeZikir':
        return Icons.lightbulb;
      case 'badgePerfectWeek':
        return Icons.calendar_today;
      default:
        return Icons.emoji_events;
    }
  }
  
  // Rozet rengi
  Color _getBadgeColor(String badgeId) {
    switch (badgeId) {
      case 'badgeFirstZikir':
        return Colors.blue;
      case 'badgeStreak7Days':
        return Colors.orange;
      case 'badgeDailyPeak':
        return Colors.green;
      case 'badgeZikir1000':
        return Colors.purple;
      case 'badgeSocialShare':
        return Colors.pink;
      case 'badgeCreativeZikir':
        return Colors.teal;
      case 'badgePerfectWeek':
        return Colors.amber;
      default:
        return Colors.blueGrey;
    }
  }
}