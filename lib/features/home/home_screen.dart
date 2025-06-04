// Dosya: lib/features/home/home_screen.dart
// Yol: C:\src\zikirmo_new\lib\features\home\home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/providers/providers.dart';
import '../../core/models/user_model.dart';
import '../../core/models/zikir_model.dart';
import '../../core/models/category_model.dart';
import '../../core/guards/email_verification_guard.dart';
import '../profile/profile_screen.dart';
import '../friends/friends_screen.dart';
import '../zikir/categories_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;
  late PageController _pageController;
  bool _authChecked = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    debugPrint('🏠 HomeScreen initialized with bottom navigation');
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthStatusOnce();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _checkAuthStatusOnce() {
    if (_authChecked) return;
    
    final authService = ref.read(authServiceProvider);
    final user = authService.currentUser;
    
    debugPrint('🔍 Auth kontrolü - Kullanıcı: ${user?.email ?? 'null'}');
    
    if (user == null) {
      debugPrint('❌ Kullanıcı yok, auth sayfasına yönlendiriliyor');
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/auth');
      }
    } else {
      debugPrint('✅ Kullanıcı mevcut, ana sayfa açılıyor');
    }
    
    _authChecked = true;
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🏠 HomeScreen build() - Tab: $_currentIndex');
    
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: [
          // Ana sayfa - Email doğrulama banner'ı ile
          EmailVerificationGuard(
            requireVerification: false,
            allowBasicUsage: true,
            child: const _HomeTab(),
          ),
          
          // Kategoriler - Temel erişim
          EmailVerificationGuard(
            requireVerification: false,
            allowBasicUsage: true,
            child: const CategoriesScreen(),
          ),
          
          // Arkadaşlar - Email doğrulama gerekli
          EmailVerificationGuard(
            requireVerification: true,
            customMessage: 'friendsRequireVerification'.tr(),
            child: const FriendsScreen(),
          ),
          
          // Profil - Temel erişim
          EmailVerificationGuard(
            requireVerification: false,
            allowBasicUsage: true,
            child: const ProfileScreen(),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey.shade600,
        backgroundColor: Colors.white,
        elevation: 8,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            activeIcon: const Icon(Icons.home),
            label: 'home'.tr(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.category_outlined),
            activeIcon: const Icon(Icons.category),
            label: 'categories'.tr(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.people_outline),
            activeIcon: const Icon(Icons.people),
            label: 'friends'.tr(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            activeIcon: const Icon(Icons.person),
            label: 'profile'.tr(),
          ),
        ],
      ),
    );
  }
}

/// Ana sayfa sekmesi
class _HomeTab extends ConsumerWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text('home'.tr()),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/notifications'),
            icon: const Icon(Icons.notifications),
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              switch (value) {
                case 'settings':
                  Navigator.pushNamed(context, '/settings');
                  break;
                case 'logout':
                  final authService = ref.read(authServiceProvider);
                  await authService.signOut();
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(context, '/auth', (route) => false);
                  }
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    const Icon(Icons.settings),
                    const SizedBox(width: 8),
                    Text('settings'.tr()),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    const Icon(Icons.logout, color: Colors.red),
                    const SizedBox(width: 8),
                    Text('signOut'.tr(), style: const TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Email doğrulama banner'ı
            const EmailVerificationBanner(),
            
            // Ana içerik
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Kullanıcı hoş geldin bölümü
                    const _UserWelcomeSection(),
                    const SizedBox(height: 24),
                    
                    // Hızlı zikir bölümü  
                    const _QuickZikirSection(),
                    const SizedBox(height: 24),
                    
                    // Popüler zikirler (kısıtlı)
                    const _PopularZikirsSection(),
                    const SizedBox(height: 24),
                    
                    // Kategoriler
                    const _CategoriesSection(),
                    const SizedBox(height: 24),
                    
                    // İstatistikler
                    const _StatsSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(context, ref),
    );
  }

  // Floating Action Button - Email doğrulama kontrolü ile
  Widget _buildFloatingActionButton(BuildContext context, WidgetRef ref) {
    return Consumer(
      builder: (context, ref, child) {
        final authStateAsync = ref.watch(authStateProvider);
        
        return authStateAsync.when(
          data: (user) {
            final isEmailVerified = user?.emailVerified ?? false;
            
            return FloatingActionButton(
              onPressed: () {
                if (isEmailVerified) {
                  // Doğrulanmış kullanıcı - normal zikir seçimi
                  Navigator.pushNamed(context, '/categories');
                } else {
                  // Doğrulanmamış kullanıcı - sadece default sayaç
                  Navigator.pushNamed(context, '/zikir_counter');
                }
              },
              backgroundColor: Theme.of(context).primaryColor,
              child: Icon(
                isEmailVerified ? Icons.add : Icons.touch_app,
                color: Colors.white,
              ),
            );
          },
          loading: () => FloatingActionButton(
            onPressed: () => Navigator.pushNamed(context, '/zikir_counter'),
            backgroundColor: Theme.of(context).primaryColor,
            child: const Icon(Icons.touch_app, color: Colors.white),
          ),
          error: (_, __) => FloatingActionButton(
            onPressed: () => Navigator.pushNamed(context, '/zikir_counter'),
            backgroundColor: Theme.of(context).primaryColor,
            child: const Icon(Icons.touch_app, color: Colors.white),
          ),
        );
      },
    );
  }
}

/// Kullanıcı hoş geldin bölümü
class _UserWelcomeSection extends ConsumerWidget {
  const _UserWelcomeSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);
    
    return userAsync.when(
      data: (user) => _buildWelcomeCard(context, user),
      loading: () => _buildLoadingCard(),
      error: (error, stack) => _buildErrorCard(context, error),
    );
  }

  Widget _buildWelcomeCard(BuildContext context, UserModel? user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Theme.of(context).primaryColor.withOpacity(0.8), Theme.of(context).primaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: Colors.white,
                child: Text(
                  user?.nickname.substring(0, 1).toUpperCase() ?? 'U',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'welcomeUser'.tr(args: [user?.nickname ?? 'defaultUser'.tr()]),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'userStats'.tr(args: [user?.level ?? 'levelBeginner'.tr(), '${user?.points ?? 0}']),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatChip('totalZikirs'.tr(), '${user?.totalZikirCount ?? 0}'),
              _buildStatChip('currentStreak'.tr(), '${user?.currentStreak ?? 0}'),
              _buildStatChip('points'.tr(), '${user?.points ?? 0}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      width: double.infinity,
      height: 120,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context, Object error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade400, size: 40),
          const SizedBox(height: 8),
          Text(
            'errorLoadingProfile'.tr(),
            style: TextStyle(color: Colors.red.shade700),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/auth', (route) => false),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('tryAgain'.tr(), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

/// Hızlı zikir bölümü - Email doğrulama kısıtlaması ile
class _QuickZikirSection extends ConsumerWidget {
  const _QuickZikirSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authStateAsync = ref.watch(authStateProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'quickZikir'.tr(),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        authStateAsync.when(
          data: (user) {
            final isEmailVerified = user?.emailVerified ?? false;
            
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickButton(
                        context,
                        'defaultCounter'.tr(),
                        Icons.touch_app,
                        Colors.blue,
                        () => Navigator.pushNamed(context, '/zikir_counter'),
                        isEnabled: true,
                        subtitle: 'alwaysAvailable'.tr(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildQuickButton(
                        context,
                        'customZikir'.tr(),
                        Icons.add_circle_outline,
                        Colors.green,
                        () {
                          if (isEmailVerified) {
                            Navigator.pushNamed(context, '/custom_zikir');
                          } else {
                            EmailVerificationDialog.show(
                              context,
                              customMessage: 'customZikirRequiresVerification'.tr(),
                            );
                          }
                        },
                        isEnabled: isEmailVerified,
                        subtitle: isEmailVerified ? 'available'.tr() : 'verificationRequired'.tr(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickButton(
                        context,
                        'browseZikirs'.tr(),
                        Icons.search,
                        Colors.purple,
                        () {
                          if (isEmailVerified) {
                            Navigator.pushNamed(context, '/categories');
                          } else {
                            EmailVerificationDialog.show(
                              context,
                              customMessage: 'browseZikirsRequiresVerification'.tr(),
                            );
                          }
                        },
                        isEnabled: isEmailVerified,
                        subtitle: isEmailVerified ? 'available'.tr() : 'verificationRequired'.tr(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildQuickButton(
                        context,
                        'zikirHistory'.tr(),
                        Icons.history,
                        Colors.orange,
                        () => Navigator.pushNamed(context, '/zikir_history'),
                        isEnabled: true,
                        subtitle: 'alwaysAvailable'.tr(),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
          loading: () => _buildQuickButtonsLoading(),
          error: (_, __) => _buildQuickButtonsError(),
        ),
      ],
    );
  }

  Widget _buildQuickButton(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    required bool isEnabled,
    String? subtitle,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isEnabled ? color.withOpacity(0.1) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isEnabled ? color.withOpacity(0.3) : Colors.grey.shade300,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon, 
              color: isEnabled ? color : Colors.grey.shade400, 
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: isEnabled ? color : Colors.grey.shade600,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: isEnabled ? color.withOpacity(0.7) : Colors.grey.shade500,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickButtonsLoading() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildQuickButtonSkeleton()),
            const SizedBox(width: 12),
            Expanded(child: _buildQuickButtonSkeleton()),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildQuickButtonSkeleton()),
            const SizedBox(width: 12),
            Expanded(child: _buildQuickButtonSkeleton()),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickButtonSkeleton() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildQuickButtonsError() {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade400),
            const SizedBox(height: 8),
            Text('errorLoadingQuickActions'.tr()),
          ],
        ),
      ),
    );
  }
}

/// Popüler zikirler bölümü - Kısıtlı erişim
class _PopularZikirsSection extends ConsumerWidget {
  const _PopularZikirsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authStateAsync = ref.watch(authStateProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'popularZikirs'.tr(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            authStateAsync.when(
              data: (user) {
                final isEmailVerified = user?.emailVerified ?? false;
                return TextButton(
                  onPressed: () {
                    if (isEmailVerified) {
                      Navigator.pushNamed(context, '/categories');
                    } else {
                      EmailVerificationDialog.show(
                        context,
                        customMessage: 'viewAllZikirsRequiresVerification'.tr(),
                      );
                    }
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('viewAll'.tr()),
                      if (!isEmailVerified) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.lock, size: 16, color: Colors.grey.shade600),
                      ],
                    ],
                  ),
                );
              },
              loading: () => TextButton(
                onPressed: null,
                child: Text('viewAll'.tr()),
              ),
              error: (_, __) => const SizedBox(),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        authStateAsync.when(
          data: (user) {
            final isEmailVerified = user?.emailVerified ?? false;
            
            if (!isEmailVerified) {
              return _buildRestrictedZikirsSection();
            }
            
            // Email doğrulanmışsa normal popüler zikirler
            final popularZikirsAsync = ref.watch(popularZikirsProvider);
            return popularZikirsAsync.when(
              data: (zikirs) => _buildZikirsList(context, zikirs, isEmailVerified),
              loading: () => _buildZikirsLoading(),
              error: (error, stack) => _buildZikirsError(context),
            );
          },
          loading: () => _buildZikirsLoading(),
          error: (_, __) => _buildZikirsError(context),
        ),
      ],
    );
  }

  // Kısıtlı zikir bölümü
  Widget _buildRestrictedZikirsSection() {
    return Container(
      height: 120,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline, color: Colors.grey.shade500, size: 32),
          const SizedBox(height: 8),
          Text(
            'verifyToAccessZikirs'.tr(),
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'useDefaultCounterForNow'.tr(),
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildZikirsList(BuildContext context, List<ZikirModel> zikirs, bool canAccess) {
    if (zikirs.isEmpty) {
      return _buildEmptyState(context, 'noPopularZikirs'.tr());
    }

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: zikirs.length,
        itemBuilder: (context, index) {
          final zikir = zikirs[index];
          return Container(
            width: 200,
            margin: EdgeInsets.only(right: index < zikirs.length - 1 ? 12 : 0),
            child: _buildZikirCard(context, zikir, canAccess),
          );
        },
      ),
    );
  }

  Widget _buildZikirCard(BuildContext context, ZikirModel zikir, bool canAccess) {
    return InkWell(
      onTap: () {
        if (canAccess) {
          Navigator.pushNamed(context, '/zikir_detail', arguments: zikir.id);
        } else {
          EmailVerificationDialog.show(
            context,
            customMessage: 'zikirDetailsRequireVerification'.tr(),
          );
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: canAccess ? Colors.blue.shade50 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: canAccess ? Colors.blue.shade200 : Colors.grey.shade300,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    zikir.getLocalizedTitle('tr'),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: canAccess ? Colors.black : Colors.grey.shade600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!canAccess)
                  Icon(Icons.lock, size: 16, color: Colors.grey.shade500),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'target'.tr(args: ['${zikir.targetCount}']),
              style: TextStyle(
                color: canAccess ? Colors.grey.shade600 : Colors.grey.shade500,
                fontSize: 12,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Icon(
                  canAccess ? Icons.play_arrow : Icons.lock_outline,
                  color: canAccess ? Colors.blue.shade600 : Colors.grey.shade500,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  canAccess ? 'startZikir'.tr() : 'verificationRequired'.tr(),
                  style: TextStyle(
                    color: canAccess ? Colors.blue.shade600 : Colors.grey.shade500,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZikirsLoading() {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        itemBuilder: (context, index) {
          return Container(
            width: 200,
            height: 120,
            margin: EdgeInsets.only(right: index < 2 ? 12 : 0),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }

  Widget _buildZikirsError(BuildContext context) {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.warning_amber, color: Colors.orange.shade600),
          const SizedBox(height: 8),
          Text('errorLoadingZikirs'.tr()),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String message) {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, color: Colors.grey.shade500),
          const SizedBox(height: 8),
          Text(message, style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}

/// Kategoriler bölümü - Temel görüntüleme
class _CategoriesSection extends ConsumerWidget {
  const _CategoriesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'categories'.tr(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/categories'),
              child: Text('viewAll'.tr()),
            ),
          ],
        ),
        const SizedBox(height: 12),
        categoriesAsync.when(
          data: (categories) => _buildCategoriesGrid(context, categories),
          loading: () => _buildCategoriesLoading(),
          error: (error, stack) => _buildCategoriesError(context),
        ),
      ],
    );
  }

  Widget _buildCategoriesGrid(BuildContext context, List<CategoryModel> categories) {
    if (categories.isEmpty) {
      return _buildEmptyState(context, 'noCategories'.tr());
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: categories.length > 4 ? 4 : categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return _buildCategoryCard(context, category);
      },
    );
  }

  Widget _buildCategoryCard(BuildContext context, CategoryModel category) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, '/category_detail', arguments: category.id),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.purple.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.purple.shade200),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getCategoryIcon(category.iconName),
              color: Colors.purple.shade600,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              category.getLocalizedName('tr'),
              style: TextStyle(
                color: Colors.purple.shade700,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String iconName) {
    switch (iconName) {
      case 'prayers':
        return Icons.favorite;
      case 'esmaUlHusna':
        return Icons.auto_awesome;
      case 'salawat':
        return Icons.star;
      default:
        return Icons.category;
    }
  }

  Widget _buildCategoriesLoading() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(child: CircularProgressIndicator()),
        );
      },
    );
  }

  Widget _buildCategoriesError(BuildContext context) {
    return Container(
      height: 100,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.warning_amber, color: Colors.orange.shade600),
          const SizedBox(height: 8),
          Text('errorLoadingCategories'.tr()),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String message) {
    return Container(
      height: 100,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.category_outlined, color: Colors.grey.shade500),
          const SizedBox(height: 8),
          Text(message, style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}

/// İstatistikler bölümü
class _StatsSection extends ConsumerWidget {
  const _StatsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userStatsAsync = ref.watch(userStatsProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'statistics'.tr(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        userStatsAsync.when(
          data: (stats) => _buildStatsCards(context, stats),
          loading: () => _buildStatsLoading(),
          error: (error, stack) => _buildStatsError(context),
        ),
      ],
    );
  }

  Widget _buildStatsCards(BuildContext context, Map<String, dynamic> stats) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'dailyZikir'.tr(),
            '${stats['thisMonthZikirs'] ?? 0}',
            Icons.today,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'achievements'.tr(),
            '${stats['badges'] ?? 0}',
            Icons.emoji_events,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: color.withOpacity(0.8),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsLoading() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(child: CircularProgressIndicator()),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(child: CircularProgressIndicator()),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsError(BuildContext context) {
    return Container(
      height: 100,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.warning_amber, color: Colors.orange.shade600),
          const SizedBox(height: 8),
          Text('errorLoadingStats'.tr()),
        ],
      ),
    );
  }
}