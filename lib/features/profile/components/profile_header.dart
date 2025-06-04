// Dosya: lib/features/profile/components/profile_header.dart
// Yol: C:\src\zikirmo_new\lib\features\profile\components\profile_header.dart

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/models/user_model.dart';

class ProfileHeader extends StatelessWidget {
  final UserModel user;
  
  const ProfileHeader({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Avatar ve düzenleme butonu
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                // Kullanıcı avatarı
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                  backgroundImage: user.profileImageUrl?.isNotEmpty == true
                      ? NetworkImage(user.profileImageUrl!)
                      : null,
                  child: user.profileImageUrl?.isEmpty != false
                      ? Text(
                          _getInitials(user.nickname),
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        )
                      : null,
                ),
                
                // Avatar düzenleme butonu
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Theme.of(context).primaryColor,
                  child: IconButton(
                    icon: const Icon(Icons.edit, size: 18, color: Colors.white),
                    onPressed: () {
                      // TODO: Avatar düzenleme ekranına git
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Kullanıcı adı ve Premium rozeti
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  user.nickname,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (user.isPremium) 
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star,
                            color: Colors.amber[700],
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Premium',
                            style: TextStyle(
                              color: Colors.amber[700],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Seviye bilgisi
            Text(
              'level'.tr() + ': ${user.level}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            
            // Puan ve ilerleme çubuğu
            Text(
              'points'.tr() + ': ${user.points}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            
            // Seviye ilerleme çubuğu
            LinearProgressIndicator(
              value: _calculateLevelProgress(user.level, user.points),
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 4),
            
            // Bir sonraki seviyeye kalan puan
            Text(
              _getRemainingPointsText(user.level, user.points),
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  // Kullanıcı adının baş harflerini almak için
  String _getInitials(String name) {
    if (name.isEmpty) return '';
    
    final nameParts = name.split(' ');
    String initials = '';
    
    for (var part in nameParts) {
      if (part.isNotEmpty) {
        initials += part[0].toUpperCase();
        if (initials.length >= 2) break;
      }
    }
    
    return initials;
  }
  
  // Seviye ilerleme oranını hesapla
  double _calculateLevelProgress(String level, int points) {
    final currentLevelMinPoints = _getCurrentLevelMinPoints(level);
    final nextLevelMinPoints = _getNextLevelPoints(level);
    
    if (nextLevelMinPoints <= currentLevelMinPoints) return 1.0;
    
    final progress = (points - currentLevelMinPoints) / (nextLevelMinPoints - currentLevelMinPoints);
    return progress.clamp(0.0, 1.0);
  }
  
  // Sonraki seviyeye kalan puanları hesapla
  String _getRemainingPointsText(String level, int points) {
    final nextLevelPoints = _getNextLevelPoints(level);
    final remaining = nextLevelPoints - points;
    
    if (remaining <= 0) {
      return 'maxLevelReached'.tr();
    }
    
    return 'pointsToNextLevel'.tr(args: [remaining.toString()]);
  }
  
  // Mevcut seviyenin minimum puanı
  int _getCurrentLevelMinPoints(String level) {
    switch (level) {
      case 'levelBeginner': return 0;
      case 'levelApprentice': return 100;
      case 'levelMaster': return 500;
      case 'levelSage': return 1000;
      case 'levelGrateful': return 2500;
      case 'levelSaint': return 5000;
      case 'levelKnower': return 10000;
      default: return 0;
    }
  }
  
  // Sonraki seviyenin minimum puanı
  int _getNextLevelPoints(String level) {
    switch (level) {
      case 'levelBeginner': return 100;
      case 'levelApprentice': return 500;
      case 'levelMaster': return 1000;
      case 'levelSage': return 2500;
      case 'levelGrateful': return 5000;
      case 'levelSaint': return 10000;
      case 'levelKnower': return 100000; // Son seviye
      default: return 100;
    }
  }
}