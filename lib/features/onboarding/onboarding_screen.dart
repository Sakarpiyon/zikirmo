// lib/features/onboarding/onboarding_screen.dart
// DÜZELTİLMİŞ ONBOARDING SCREEN - SharedPreferences entegrasyonu eklendi
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../routes.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Onboarding ekranları için içerik
  final List<Map<String, dynamic>> _slides = [
    {
      'title': 'onboardingWelcome',
      'description': 'onboardingDescription', 
      'icon': Icons.volunteer_activism,
      'color': Colors.teal,
    },
    {
      'title': 'dailyZikir',
      'description': 'Günlük zikirlerinizi düzenli olarak takip edin ve hatırlatıcılar alın.',
      'icon': Icons.calendar_today,
      'color': Colors.blue,
    },
    {
      'title': 'Arkadaşlarınızla Bağlantıda Kalın',
      'description': 'Arkadaşlarınızla zikir hedeflerinizi paylaşın ve birbirinizi motive edin.',
      'icon': Icons.people,
      'color': Colors.green,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Atla butonu
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: () => _completeOnboarding(),
                  child: Text(
                    'Atla',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
            
            // Sayfa görünümü
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _slides.length,
                itemBuilder: (context, index) => _buildPage(
                  title: _slides[index]['title'],
                  description: _slides[index]['description'],
                  icon: _slides[index]['icon'],
                  color: _slides[index]['color'],
                ),
              ),
            ),
            
            // Sayfa göstergeleri
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _slides.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    width: _currentPage == index ? 24 : 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _currentPage == index 
                          ? _slides[_currentPage]['color']
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
            ),
            
            // İleri/Başla butonu
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPage == _slides.length - 1) {
                          _completeOnboarding();
                        } else {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _slides[_currentPage]['color'],
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: _slides[_currentPage]['color'].withOpacity(0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        _currentPage == _slides.length - 1
                            ? 'onboardingGetStarted'.tr()
                            : 'İleri',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  
                  // Son sayfada login linkini göster
                  if (_currentPage == _slides.length - 1) ...[
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Zaten hesabınız var mı? ',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _completeOnboarding(),
                          child: Text(
                            'Giriş Yapın',
                            style: TextStyle(
                              color: _slides[_currentPage]['color'],
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Onboarding sayfası görünümü
  Widget _buildPage({
    required String title, 
    required String description, 
    required IconData icon,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // İkon container
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              size: 80,
              color: color,
            ),
          ),
          
          const SizedBox(height: 48),
          
          // Başlık
          Text(
            title.tr(),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 20),
          
          // Açıklama
          Text(
            description.tr(),
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Onboarding tamamlandığını kaydet ve login sayfasına yönlendir
  Future<void> _completeOnboarding() async {
    try {
      debugPrint('🏁 Onboarding tamamlanıyor...');
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_completed', true);
      
      debugPrint('✅ Onboarding tamamlandı olarak kaydedildi');
      
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      }
    } catch (e) {
      debugPrint('❌ Onboarding tamamlama hatası: $e');
      // Hata durumunda da login'e yönlendir
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}