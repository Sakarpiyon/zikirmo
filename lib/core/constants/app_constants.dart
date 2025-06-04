import 'package:flutter/material.dart';

class AppConstants {
  AppConstants._();

  // Uygulama bilgileri
  static const String appName = 'Zikir Matik';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Zikir takip ve sosyal özellikler uygulaması';

  // API ve Servis sabitleri
  static const String firebaseProjectId = 'zikirmatik-be5c0';
  static const String firestoreRegion = 'europe-west1';
  
  // Koleksiyon isimleri
  static const String usersCollection = 'users';
  static const String zikirsCollection = 'zikirler';
  static const String categoriesCollection = 'categories';
  static const String userZikirsCollection = 'user_zikirs';
  static const String friendRequestsCollection = 'friend_requests';
  static const String messagesCollection = 'messages';
  static const String giftsCollection = 'gifts';
  static const String notificationsCollection = 'notifications';
  static const String challengesCollection = 'challenges';
  static const String badgeDefinitionsCollection = 'badge_definitions';
  static const String pointsCollection = 'points';
  static const String dailyGoalsCollection = 'daily_goals';
  static const String settingsCollection = 'settings';

  // Zikir sayacı sabitleri
  static const double minCounterSize = 80.0;
  static const double maxCounterSize = 150.0;
  static const double defaultCounterSize = 100.0;
  static const int defaultZikirTarget = 33;
  static const int maxZikirTarget = 9999;
  static const Duration counterAnimationDuration = Duration(milliseconds: 150);

  // Puanlama sistemi sabitleri
  static const int pointsPerZikir = 1;
  static const int pointsPerDailyGoal = 15;
  static const int pointsPerStreak7Days = 25;
  static const int pointsPerStreak30Days = 100;
  static const int pointsPerBadge = 20;
  static const int pointsPerCustomZikir = 5;
  static const int pointsPerFriendInvite = 15;
  static const int pointsPerPerfectWeek = 50;
  static const int pointsPerLevelUp = 30;

  // Seviye sistemi sabitleri
  static const Map<String, int> levelThresholds = {
    'levelBeginner': 0,
    'levelApprentice': 100,
    'levelMaster': 500,
    'levelSage': 1000,
    'levelGrateful': 2500,
    'levelSaint': 5000,
    'levelKnower': 10000,
  };

  // Freemium limitler
  static const int freemiumFriendLimit = 20;
  static const int freemiumCustomZikirLimit = 5;
  static const int freemiumDailyReminderLimit = 1;
  static const int premiumUnlimitedValue = -1;

  // Zaman sabitleri
  static const Duration sessionTimeout = Duration(minutes: 30);
  static const Duration cacheExpiry = Duration(hours: 1);
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration notificationDelay = Duration(seconds: 2);
  static const Duration splashScreenDuration = Duration(seconds: 3);

  // Sayfa sabitleri
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  static const int leaderboardLimit = 50;
  static const int friendsListLimit = 100;

  // Mesajlaşma sabitleri
  static const int maxMessageLength = 500;
  static const int maxChatHistory = 100;
  static const Duration messageEditTimeLimit = Duration(minutes: 5);

  // Medya sabitleri
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const int maxAudioDuration = 60; // 60 saniye
  static const List<String> supportedImageFormats = ['jpg', 'jpeg', 'png', 'webp'];
  static const List<String> supportedAudioFormats = ['mp3', 'wav', 'aac', 'm4a'];

  // Validasyon sabitleri
  static const int minNicknameLength = 3;
  static const int maxNicknameLength = 30;
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 128;
  static const int maxAboutMeLength = 500;
  static const int maxZikirTitleLength = 100;
  static const int maxZikirDescriptionLength = 1000;

  // Animasyon sabitleri
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);
  static const Curve defaultAnimationCurve = Curves.easeInOut;

  // Tema sabitleri
  static const Color primaryColor = Color(0xFF00897B);
  static const Color accentColor = Color(0xFF26A69A);
  static const Color errorColor = Colors.red;
  static const Color successColor = Colors.green;
  static const Color warningColor = Colors.orange;
  static const Color infoColor = Colors.blue;

  // Spacing sabitleri
  static const double smallSpacing = 8.0;
  static const double mediumSpacing = 16.0;
  static const double largeSpacing = 24.0;
  static const double extraLargeSpacing = 32.0;

  // Border radius sabitleri
  static const double smallBorderRadius = 8.0;
  static const double mediumBorderRadius = 12.0;
  static const double largeBorderRadius = 16.0;
  static const double circleBorderRadius = 50.0;

  // Elevation sabitleri
  static const double lowElevation = 2.0;
  static const double mediumElevation = 4.0;
  static const double highElevation = 8.0;

  // Font size sabitleri
  static const double smallFontSize = 12.0;
  static const double mediumFontSize = 14.0;
  static const double largeFontSize = 16.0;
  static const double extraLargeFontSize = 18.0;
  static const double titleFontSize = 20.0;
  static const double headlineFontSize = 24.0;

  // Icon size sabitleri
  static const double smallIconSize = 16.0;
  static const double mediumIconSize = 24.0;
  static const double largeIconSize = 32.0;
  static const double extraLargeIconSize = 48.0;

  // SharedPreferences keyleri
  static const String isFirstLaunchKey = 'is_first_launch';
  static const String userIdKey = 'user_id';
  static const String languageKey = 'language';
  static const String themeModeKey = 'theme_mode';
  static const String notificationsEnabledKey = 'notifications_enabled';
  static const String soundEnabledKey = 'sound_enabled';
  static const String vibrationEnabledKey = 'vibration_enabled';
  static const String counterSizeKey = 'counter_size';
  static const String dailyReminderTimeKey = 'daily_reminder_time';
  static const String lastSyncTimeKey = 'last_sync_time';

  // Hata mesajları
  static const String networkErrorMessage = 'İnternet bağlantısı kontrol edilemedi';
  static const String authErrorMessage = 'Kimlik doğrulama hatası';
  static const String permissionErrorMessage = 'İzin hatası';
  static const String storageErrorMessage = 'Depolama hatası';
  static const String unknownErrorMessage = 'Bilinmeyen hata oluştu';

  // Başarı mesajları
  static const String saveSuccessMessage = 'Başarıyla kaydedildi';
  static const String updateSuccessMessage = 'Başarıyla güncellendi';
  static const String deleteSuccessMessage = 'Başarıyla silindi';
  static const String sendSuccessMessage = 'Başarıyla gönderildi';

  // Regex patternleri
  static const String emailPattern = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
  static const String phonePattern = r'^\+?[1-9]\d{1,14}$';
  static const String nicknamePattern = r'^[a-zA-ZğüşıöçĞÜŞİÖÇ0-9_\s]{3,30}$';
  static const String passwordPattern = r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d@$!%*#?&]{6,}$';

  // Sosyal medya URL patternleri
  static const String instagramPattern = r'^@[A-Za-z0-9_.]+$';
  static const String twitterPattern = r'^@[A-Za-z0-9_]+$';
  static const String facebookPattern = r'^[A-Za-z0-9.]+$';
  static const String spotifyPattern = r'^[A-Za-z0-9]+$';
  static const String blueskyPattern = r'^@[A-Za-z0-9_.]+$';

  // Yardımcı metotlar
  static int getLevelThreshold(String level) {
    return levelThresholds[level] ?? 0;
  }

  static String calculateLevel(int points) {
    for (var entry in levelThresholds.entries.toList().reversed) {
      if (points >= entry.value) {
        return entry.key;
      }
    }
    return 'levelBeginner';
  }

  static int getNextLevelPoints(String currentLevel) {
    final levels = levelThresholds.entries.toList();
    final currentIndex = levels.indexWhere((entry) => entry.key == currentLevel);
    
    if (currentIndex == -1 || currentIndex == levels.length - 1) {
      return levelThresholds.values.last;
    }
    
    return levels[currentIndex + 1].value;
  }
}