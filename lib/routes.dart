// Dosya: lib/routes.dart
// Yol: C:\src\zikirmo_new\lib\routes.dart

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'core/guards/email_verification_guard.dart';
import 'features/splash/splash_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/auth/auth_screen.dart';
import 'features/auth/email_verification_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/auth/forgot_password_screen.dart';
import 'features/home/home_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/profile/edit_profile_screen.dart';
import 'features/profile/social_links_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/zikir/zikir_counter_screen.dart';
import 'features/zikir/zikir_detail_screen.dart';
import 'features/categories/category_screen.dart';
import 'features/categories/category_detail_screen.dart';
import 'features/friends/friends_screen.dart';
import 'features/friends/add_friend_screen.dart';
import 'features/friends/friend_profile_screen.dart';
import 'features/friends/user_search_screen.dart';
import 'features/leaderboard/leaderboard_screen.dart';
import 'features/membership/membership_info_screen.dart';
import 'features/rewards/reward_store_screen.dart';
import 'features/challenges/challenge_screen.dart';
import 'features/messages/send_message_screen.dart';
import 'features/gifts/send_gift_screen.dart';
import 'features/zikir/categories_screen.dart';
import 'features/zikir/suggested_zikirs_screen.dart';
import 'features/admin/admin_settings_screen.dart';
import 'features/premium/premium_screen.dart';
import 'features/notifications/notifications_screen.dart';
import 'features/zikir/custom_zikir_screen.dart';
import 'features/history/zikir_history_screen.dart';
import 'features/messages/messages_list_screen.dart';

class AppRoutes {
  // Ana route'lar
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String auth = '/auth';
  static const String emailVerification = '/email_verification';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot_password';
  static const String home = '/home';
  
  // Profil route'ları
  static const String profile = '/profile';
  static const String editProfile = '/edit_profile';
  static const String socialLinks = '/social_links';
  
  // Ayar route'ları
  static const String settings = '/settings';
  
  // Zikir route'ları
  static const String zikirCounter = '/zikir_counter';
  static const String zikirDetail = '/zikir_detail';
  static const String customZikir = '/custom_zikir';
  static const String zikirHistory = '/zikir_history';
  
  // Kategori route'ları
  static const String categories = '/categories';
  static const String categoryDetail = '/category_detail';
  static const String zikirCategories = '/zikir_categories';
  static const String suggestedZikirs = '/suggested_zikirs';
  
  // Arkadaş route'ları
  static const String friends = '/friends';
  static const String addFriend = '/add_friend';
  static const String friendProfile = '/friend_profile';
  static const String userSearch = '/user_search';
  
  // Sosyal route'lar
  static const String leaderboard = '/leaderboard';
  static const String challenges = '/challenges';
  
  // Mesajlaşma route'ları
  static const String messages = '/messages';
  static const String messagesList = '/messages_list';
  static const String sendMessage = '/send_message';
  
  // Hediye route'ları
  static const String sendGift = '/send_gift';
  static const String rewardStore = '/reward_store';
  
  // Premium route'ları
  static const String premium = '/premium';
  static const String membershipInfo = '/membership_info';
  
  // Bildirim route'ları
  static const String notifications = '/notifications';
  
  // Admin route'ları
  static const String adminSettings = '/admin_settings';
  
  // Gelecek özellikler
  static const String statistics = '/statistics';
  static const String privacyPolicy = '/privacy_policy';
  static const String termsOfService = '/terms_of_service';
  static const String purchaseHistory = '/purchase_history';
  static const String subscriptionManagement = '/subscription_management';

  AppRoutes._();
}

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final args = settings.arguments;
    
    switch (settings.name) {
      // Ana route'lar - EMAIL DOĞRULAMASİZ
      case AppRoutes.splash:
        return _createRoute(const SplashScreen());
        
      case AppRoutes.onboarding:
        return _createRoute(const OnboardingScreen());
        
      case AppRoutes.auth:
        return _createRoute(const AuthScreen());

      case AppRoutes.emailVerification:
        return _createRoute(const EmailVerificationScreen());
        
      case AppRoutes.login:
        return _createRoute(const AuthScreen());
        
      case AppRoutes.register:
        return _createRoute(const AuthScreen());

      case AppRoutes.forgotPassword:
        return _createRoute(const ForgotPasswordScreen());
        
      // Ana sayfa - EMAIL DOĞRULAMASİZ (temel erişim)
      case AppRoutes.home:
        return _createRoute(
          EmailVerificationGuard(
            requireVerification: false,
            child: const HomeScreen(),
          ),
        );
      
      // Profil route'ları
      case AppRoutes.profile:
        return _createRoute(
          EmailVerificationGuard(
            requireVerification: false,
            child: const ProfileScreen(),
          ),
        );
        
      case AppRoutes.editProfile:
        return _createRoute(
          EmailVerificationGuard(
            requireVerification: true,
            child: const EditProfileScreen(),
          ),
        );
        
      case AppRoutes.socialLinks:
        return _createRoute(
          EmailVerificationGuard(
            requireVerification: true,
            child: const SocialLinksScreen(),
          ),
        );
        
      // Ayar route'ları - EMAIL DOĞRULAMASİZ
      case AppRoutes.settings:
        return _createRoute(
          EmailVerificationGuard(
            requireVerification: false,
            child: const SettingsScreen(),
          ),
        );
        
      // Zikir route'ları - TEMEL ERİŞİM SERBEST
      case AppRoutes.zikirCounter:
        if (args is String) {
          return _createRoute(
            EmailVerificationGuard(
              requireVerification: false,
              child: ZikirCounterScreen(zikirId: args),
            ),
          );
        }
        return _createRoute(
          EmailVerificationGuard(
            requireVerification: false,
            child: const ZikirCounterScreen(),
          ),
        );
        
      case AppRoutes.zikirDetail:
        if (args is String) {
          return _createRoute(
            EmailVerificationGuard(
              requireVerification: false,
              child: ZikirDetailScreen(zikirId: args),
            ),
          );
        }
        return _errorRoute('zikirNotFound');
        
      // CUSTOM ZİKİR - EMAIL DOĞRULAMASİ GEREKLİ
      case AppRoutes.customZikir:
        return _createRoute(
          EmailVerificationGuard(
            requireVerification: true,
            child: const CustomZikirScreen(),
          ),
        );
        
      case AppRoutes.zikirHistory:
        return _createRoute(
          EmailVerificationGuard(
            requireVerification: false,
            child: const ZikirHistoryScreen(),
          ),
        );
        
      // Kategori route'ları - SERBEST ERİŞİM
      case AppRoutes.categories:
        return _createRoute(
          EmailVerificationGuard(
            requireVerification: false,
            child: const CategoryScreen(),
          ),
        );
        
      case AppRoutes.categoryDetail:
        if (args is String) {
          return _createRoute(
            EmailVerificationGuard(
              requireVerification: false,
              child: CategoryDetailScreen(categoryId: args),
            ),
          );
        }
        return _errorRoute('categoryNotFound');
        
      case AppRoutes.zikirCategories:
        return _createRoute(
          EmailVerificationGuard(
            requireVerification: false,
            child: const CategoriesScreen(),
          ),
        );
        
      case AppRoutes.suggestedZikirs:
        return _createRoute(
          EmailVerificationGuard(
            requireVerification: false,
            child: const SuggestedZikirsScreen(),
          ),
        );
        
      // ARKADAŞ ROUTE'LARI - EMAIL DOĞRULAMASİ GEREKLİ
      case AppRoutes.friends:
        return _createRoute(
          EmailVerificationGuard(
            requireVerification: true,
            child: const FriendsScreen(),
          ),
        );
        
      case AppRoutes.addFriend:
        return _createRoute(
          EmailVerificationGuard(
            requireVerification: true,
            child: const AddFriendScreen(),
          ),
        );
        
      case AppRoutes.friendProfile:
        if (args is String) {
          return _createRoute(
            EmailVerificationGuard(
              requireVerification: true,
              child: FriendProfileScreen(userId: args),
            ),
          );
        }
        return _errorRoute('userNotFound');
        
      case AppRoutes.userSearch:
        return _createRoute(
          EmailVerificationGuard(
            requireVerification: true,
            child: const UserSearchScreen(),
          ),
        );
        
      // Sosyal route'lar - EMAIL DOĞRULAMASİ GEREKLİ
      case AppRoutes.leaderboard:
        return _createRoute(
          EmailVerificationGuard(
            requireVerification: true,
            child: const LeaderboardScreen(),
          ),
        );
        
      case AppRoutes.challenges:
        return _createRoute(
          EmailVerificationGuard(
            requireVerification: true,
            child: const ChallengeScreen(),
          ),
        );
        
      // MESAJLAŞMA - EMAIL DOĞRULAMASİ GEREKLİ
      case AppRoutes.messagesList:
        return _createRoute(
          EmailVerificationGuard(
            requireVerification: true,
            child: const MessagesListScreen(),
          ),
        );
        
      case AppRoutes.sendMessage:
        if (args is String) {
          return _createRoute(
            EmailVerificationGuard(
              requireVerification: true,
              child: SendMessageScreen(receiverId: args),
            ),
          );
        }
        return _errorRoute('invalidReceiver');
      
      // HEDİYE ROUTE'LARI - EMAIL DOĞRULAMASİ GEREKLİ
      case AppRoutes.sendGift:
        if (args is String) {
          return _createRoute(
            EmailVerificationGuard(
              requireVerification: true,
              child: SendGiftScreen(receiverId: args),
            ),
          );
        }
        return _errorRoute('invalidReceiver');
        
      case AppRoutes.rewardStore:
        return _createRoute(
          EmailVerificationGuard(
            requireVerification: true,
            child: const RewardStoreScreen(),
          ),
        );
        
      // Premium route'ları - SERBEST ERİŞİM
      case AppRoutes.premium:
        return _createRoute(
          EmailVerificationGuard(
            requireVerification: false,
            child: const PremiumScreen(),
          ),
        );
        
      case AppRoutes.membershipInfo:
        return _createRoute(
          EmailVerificationGuard(
            requireVerification: false,
            child: const MembershipInfoScreen(),
          ),
        );
        
      // Bildirim route'ları - EMAIL DOĞRULAMASİ GEREKLİ
      case AppRoutes.notifications:
        return _createRoute(
          EmailVerificationGuard(
            requireVerification: true,
            child: const NotificationsScreen(),
          ),
        );
        
      // Admin route'ları - EMAIL DOĞRULAMASİ GEREKLİ
      case AppRoutes.adminSettings:
        return _createRoute(
          EmailVerificationGuard(
            requireVerification: true,
            child: const AdminSettingsScreen(),
          ),
        );
        
      // Placeholder route'lar
      case AppRoutes.statistics:
        return _placeholderRoute('detailedStatistics', 'statisticsComingSoon');
        
      case AppRoutes.privacyPolicy:
        return _placeholderRoute('privacyPolicy', 'pageInPreparation');
        
      case AppRoutes.termsOfService:
        return _placeholderRoute('termsOfService', 'pageInPreparation');
        
      case AppRoutes.purchaseHistory:
        return _placeholderRoute('purchaseHistory', 'featureComingSoon');
        
      case AppRoutes.subscriptionManagement:
        return _placeholderRoute('subscriptionManagement', 'featureComingSoon');
        
      // Varsayılan (404)
      default:
        return _errorRoute('pageNotFound');
    }
  }
  
  // Standart route oluşturma
  static Route<dynamic> _createRoute(Widget page) {
    return MaterialPageRoute(builder: (_) => page);
  }
  
  // Hata route'u
  static Route<dynamic> _errorRoute(String errorKey) {
    return MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(title: Text(errorKey.tr())),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
              const SizedBox(height: 16),
              Text(
                errorKey.tr(),
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text('goBack'.tr()),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Placeholder route'u
  static Route<dynamic> _placeholderRoute(String titleKey, String messageKey) {
    return MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(title: Text(titleKey.tr())),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.construction, size: 64, color: Colors.orange[400]),
              const SizedBox(height: 16),
              Text(
                titleKey.tr(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  messageKey.tr(),
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text('goBack'.tr()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}