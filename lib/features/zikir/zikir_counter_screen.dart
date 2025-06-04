// Dosya: lib/features/zikir/zikir_counter_screen.dart
// Yol: C:\src\zikirmo_new\lib\features\zikir\zikir_counter_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/providers.dart';
import '../../core/models/zikir_model.dart';
import '../../core/constants/app_constants.dart';
import '../zikir/components/zikir_counter_widget.dart';

class ZikirCounterScreen extends ConsumerStatefulWidget {
  final String? zikirId;

  const ZikirCounterScreen({Key? key, this.zikirId}) : super(key: key);

  @override
  ConsumerState<ZikirCounterScreen> createState() => _ZikirCounterScreenState();
}

class _ZikirCounterScreenState extends ConsumerState<ZikirCounterScreen> with SingleTickerProviderStateMixin {
  // Sayaç pozisyonu
  Offset _counterPosition = const Offset(0, 0);
  
  // Sayaç boyutu (0.0-1.0 arası normalized değer)
  double _counterSize = 0.5;
  
  // Ayarlar
  bool _useVibration = true;
  bool _useSound = true;
  bool _showOnlyCounter = false; // Premium özelliği
  bool _wholeScreenTappable = false; // Premium özelliği
  
  // Animasyon
  late AnimationController _animationController;
  late Animation<double> _animation;
  
  // Zikir detayları
  ZikirModel? _zikir;
  bool _isLoading = true;
  bool _isPremium = false;
  bool _isEmailVerified = false;
  bool _isDefaultMode = false; // Email doğrulama yapılmamış kullanıcılar için
  
  @override
  void initState() {
    super.initState();
    
    // Animasyon kontrolcüsü
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    
    _animation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationController.reverse();
      }
    });
    
    // Kullanıcı ayarlarını yükle
    _loadUserSettings();
    
    // Zikir bilgilerini yükle
    if (widget.zikirId != null) {
      _loadZikirDetails();
    } else {
      // Email doğrulama kontrolü yap
      _checkEmailVerificationAndSetDefault();
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  // Email doğrulama kontrolü ve default mod ayarı
  Future<void> _checkEmailVerificationAndSetDefault() async {
    final authStateAsync = ref.read(authStateProvider);
    
    authStateAsync.whenData((user) {
      if (user != null) {
        setState(() {
          _isEmailVerified = user.emailVerified;
          _isDefaultMode = !user.emailVerified;
          _isLoading = false;
        });
        
        if (!user.emailVerified) {
          debugPrint('🔒 Email doğrulanmamış - Default mod aktif');
        }
      } else {
        setState(() {
          _isDefaultMode = true;
          _isLoading = false;
        });
      }
    });
  }
  
  // Kullanıcı ayarlarını yükleme
  Future<void> _loadUserSettings() async {
    // Ekran merkezini hesapla (ilk defa kullanılıyorsa)
    _calculateScreenCenter();
    
    // Premium özelliklerini kontrol et
    final authService = ref.read(authServiceProvider);
    final currentUser = authService.currentUser;
    
    if (currentUser != null) {
      final isPremium = await authService.checkIfUserIsPremium();
      
      if (mounted) {
        setState(() {
          _isPremium = isPremium;
          _isEmailVerified = currentUser.emailVerified;
        });
      }
    }
  }
  
  // Zikir detaylarını yükleme
  Future<void> _loadZikirDetails() async {
    if (widget.zikirId == null) return;
    
    try {
      // Email doğrulama kontrolü
      final authStateAsync = ref.read(authStateProvider);
      await authStateAsync.when(
        data: (user) async {
          final isVerified = user?.emailVerified ?? false;
          
          if (!isVerified) {
            // Email doğrulanmamışsa default moda geç
            if (mounted) {
              setState(() {
                _isDefaultMode = true;
                _isEmailVerified = false;
                _isLoading = false;
              });
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('zikirAccessRequiresVerification'.tr()),
                  action: SnackBarAction(
                    label: 'verify'.tr(),
                    onPressed: () => Navigator.pushNamed(context, '/email_verification'),
                  ),
                ),
              );
            }
            return;
          }
          
          // Email doğrulandıysa zikir bilgilerini getir
          final zikirAsync = ref.read(zikirProviderFamily(widget.zikirId!));
          await zikirAsync.when(
            data: (zikir) async {
              if (mounted) {
                setState(() {
                  _zikir = zikir;
                  _isEmailVerified = true;
                  _isDefaultMode = false;
                  _isLoading = false;
                });
              }
            },
            loading: () {},
            error: (error, stack) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                  _isDefaultMode = true; // Hata durumunda default moda geç
                });
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('zikirLoadError'.tr())),
                );
              }
            },
          );
        },
        loading: () {},
        error: (error, stack) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _isDefaultMode = true;
            });
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isDefaultMode = true;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('zikirLoadError'.tr())),
        );
      }
    }
  }
  
  // Ekran merkezini hesaplama
  void _calculateScreenCenter() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final size = MediaQuery.of(context).size;
      setState(() {
        _counterPosition = Offset(size.width / 2 - 90, size.height / 2 - 90);
      });
    });
  }
  
  // Sayacı artırma
  void _incrementCounter() async {
    // Sayaç görüntüsü ve animasyonu
    _animationController.forward();
    
    // Titreşim
    if (_useVibration) {
      final hapticService = ref.read(hapticServiceProvider);
      await hapticService.lightImpact();
    }
    
    // Ses
    if (_useSound) {
      // TODO: Sound service implementation
    }
    
    // Sayaç değerini artır
    ref.read(zikirCounterProvider.notifier).increment();
    
    // Tamamlanma kontrolü
    final counter = ref.read(zikirCounterProvider);
    final targetCount = _getTargetCount();
    
    if (counter == targetCount) {
      // Hedef tamamlandı
      _showCompletionDialog();
      
      // Titreşim
      if (_useVibration) {
        final hapticService = ref.read(hapticServiceProvider);
        await hapticService.heavyImpact();
      }
    }
  }
  
  // Hedef sayısını getir
  int _getTargetCount() {
    if (_isDefaultMode) {
      return 33; // Default hedef
    }
    return _zikir?.targetCount ?? 33;
  }
  
  // Zikir başlığını getir
  String _getZikirTitle() {
    if (_isDefaultMode) {
      return 'defaultZikirCounter'.tr();
    }
    return _zikir?.getLocalizedTitle(context.locale.languageCode) ?? 'zikirCounter'.tr();
  }
  
  // Tamamlama diyaloğu
  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('congratulations'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_isDefaultMode ? 'defaultZikirCompleted'.tr() : 'zikirCompleted'.tr()),
            if (_isDefaultMode) ...[
              const SizedBox(height: 16),
              Text(
                'verifyToSaveProgress'.tr(),
                style: TextStyle(
                  color: Colors.orange.shade700,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (_isDefaultMode)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/email_verification');
              },
              child: Text('verifyNow'.tr()),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('continue'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetCounter();
            },
            child: Text('reset'.tr()),
          ),
        ],
      ),
    );
  }
  
  // Sayacı sıfırlama
  void _resetCounter() {
    ref.read(zikirCounterProvider.notifier).reset();
  }
  
  // Ayarlar modalını gösterme
  void _showSettingsModal() {
    showModalBottomSheet(
      context: context,
      builder: (context) => _buildSettingsModal(),
    );
  }
  
  // Ayarlar modalı içeriği
  Widget _buildSettingsModal() {
    return StatefulBuilder(
      builder: (context, setState) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'counterSettings'.tr(),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              
              // Default mod uyarısı
              if (_isDefaultMode) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    border: Border.all(color: Colors.orange.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange.shade600),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'defaultModeActive'.tr(),
                          style: TextStyle(color: Colors.orange.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Titreşim ayarı
              SwitchListTile(
                title: Text('vibration'.tr()),
                value: _useVibration,
                onChanged: (value) {
                  setState(() {
                    _useVibration = value;
                  });
                  _saveSettings();
                },
              ),
              
              // Ses ayarı
              SwitchListTile(
                title: Text('sound'.tr()),
                value: _useSound,
                onChanged: (value) {
                  setState(() {
                    _useSound = value;
                  });
                  _saveSettings();
                },
              ),
              
              const Divider(),
              
              // Premium özellikleri (sadece email doğrulanmış kullanıcılar için)
              if (_isEmailVerified && _isPremium) ...[
                Text(
                  'premiumFeatures'.tr(),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                
                SwitchListTile(
                  title: Text('showOnlyCounter'.tr()),
                  value: _showOnlyCounter,
                  onChanged: (value) {
                    setState(() {
                      _showOnlyCounter = value;
                    });
                    this.setState(() {});
                    _saveSettings();
                  },
                ),
                
                SwitchListTile(
                  title: Text('wholeScreenTappable'.tr()),
                  value: _wholeScreenTappable,
                  onChanged: (value) {
                    setState(() {
                      _wholeScreenTappable = value;
                    });
                    this.setState(() {});
                    _saveSettings();
                  },
                ),
                
                ListTile(
                  title: Text('counterSize'.tr()),
                  subtitle: Slider(
                    value: _counterSize,
                    min: 0.2,
                    max: 1.0,
                    divisions: 8,
                    label: (_counterSize * 100).round().toString() + '%',
                    onChanged: (value) {
                      setState(() {
                        _counterSize = value;
                      });
                      this.setState(() {});
                      _saveSettings();
                    },
                  ),
                ),
              ] else if (_isEmailVerified && !_isPremium) ...[
                // Premium olmayan ama email doğrulanmış kullanıcılar
                ListTile(
                  title: Text('premiumFeatures'.tr()),
                  subtitle: Text('premiumFeaturesDescription'.tr()),
                  trailing: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/premium');
                    },
                    child: Text('upgradeToPremium'.tr()),
                  ),
                ),
              ] else if (!_isEmailVerified) ...[
                // Email doğrulanmamış kullanıcılar
                ListTile(
                  title: Text('advancedFeatures'.tr()),
                  subtitle: Text('verifyEmailForMoreFeatures'.tr()),
                  trailing: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/email_verification');
                    },
                    child: Text('verifyNow'.tr()),
                  ),
                ),
              ],
              
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
  
  // Ayarları kaydetme
  void _saveSettings() async {
    // TODO: SharedPreferences implementation
  }
  
  @override
  Widget build(BuildContext context) {
    final counter = ref.watch(zikirCounterProvider);
    final targetCount = _getTargetCount();
    
    // İlerleme oranı
    final progress = counter / targetCount;
    
    return Scaffold(
      appBar: _showOnlyCounter ? null : AppBar(
        title: Text(_getZikirTitle()),
        backgroundColor: _isDefaultMode ? Colors.orange : Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (_isDefaultMode) ...[
            IconButton(
              icon: const Icon(Icons.verified_user),
              onPressed: () => Navigator.pushNamed(context, '/email_verification'),
              tooltip: 'verifyToSaveProgress'.tr(),
            ),
          ],
          IconButton(
            icon: Icon(_useVibration ? Icons.vibration : Icons.vibration_outlined),
            onPressed: () {
              setState(() {
                _useVibration = !_useVibration;
              });
              _saveSettings();
            },
            tooltip: _useVibration ? 'disableVibration'.tr() : 'enableVibration'.tr(),
          ),
          IconButton(
            icon: Icon(_useSound ? Icons.volume_up : Icons.volume_off),
            onPressed: () {
              setState(() {
                _useSound = !_useSound;
              });
              _saveSettings();
            },
            tooltip: _useSound ? 'disableSound'.tr() : 'enableSound'.tr(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Stack(
                children: [
                  // Default mod banner'ı
                  if (_isDefaultMode && !_showOnlyCounter)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.orange.shade700),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'defaultModeActive'.tr(),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange.shade800,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    'verifyToSaveProgress'.tr(),
                                    style: TextStyle(
                                      color: Colors.orange.shade700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pushNamed(context, '/email_verification'),
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.orange.shade200,
                                foregroundColor: Colors.orange.shade800,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              ),
                              child: Text('verifyNow'.tr(), style: const TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  
                  // Tüm ekran tıklama alanı (premium özelliği ve email doğrulandıysa)
                  if (_wholeScreenTappable && _isEmailVerified)
                    GestureDetector(
                      onTap: _incrementCounter,
                      child: Container(
                        width: double.infinity,
                        height: double.infinity,
                        color: Colors.transparent,
                      ),
                    ),
                  
                  // Zikir bilgileri üst panel
                  if (!_showOnlyCounter)
                    Positioned(
                      top: _isDefaultMode ? 80 : 16,
                      left: 16,
                      right: 16,
                      child: Column(
                        children: [
                          // Zikir adı ve hedef
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  _getZikirTitle(),
                                  style: Theme.of(context).textTheme.headlineSmall,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                'target'.tr(args: [targetCount.toString()]),
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          
                          // İlerleme çubuğu
                          LinearProgressIndicator(
                            value: progress.clamp(0.0, 1.0),
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              progress >= 1.0 
                                  ? Colors.green 
                                  : (_isDefaultMode ? Colors.orange : Theme.of(context).primaryColor),
                            ),
                            minHeight: 10,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          
                          // Sayı göstergesi
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              '$counter / $targetCount',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  // Zikir sayacı (sürüklenebilir sadece premium ve email doğrulandıysa)
                  Positioned(
                    left: _counterPosition.dx,
                    top: _counterPosition.dy,
                    child: GestureDetector(
                      onPanUpdate: (_isPremium && _isEmailVerified) ? (details) {
                        setState(() {
                          _counterPosition = Offset(
                            (_counterPosition.dx + details.delta.dx).clamp(0, MediaQuery.of(context).size.width - 180 * _counterSize),
                            (_counterPosition.dy + details.delta.dy).clamp(0, MediaQuery.of(context).size.height - 180 * _counterSize),
                          );
                        });
                        _saveSettings();
                      } : null,
                      child: ZikirCounterWidget(
                        count: counter,
                        targetCount: targetCount,
                        animation: _animation,
                        onTap: _incrementCounter,
                        size: AppConstants.minCounterSize + (AppConstants.maxCounterSize - AppConstants.minCounterSize) * _counterSize,
                        isCompleted: counter >= targetCount,
                        isDefaultMode: _isDefaultMode,
                      ),
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: _showOnlyCounter
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Ayarlar butonu
                FloatingActionButton(
                  heroTag: 'settings',
                  onPressed: _showSettingsModal,
                  mini: true,
                  backgroundColor: _isDefaultMode ? Colors.orange : Theme.of(context).primaryColor,
                  child: const Icon(Icons.settings, color: Colors.white),
                ),
                const SizedBox(height: 8),
                
                // Sıfırlama butonu
                FloatingActionButton(
                  heroTag: 'reset',
                  onPressed: _resetCounter,
                  mini: true,
                  backgroundColor: Colors.red,
                  child: const Icon(Icons.refresh, color: Colors.white),
                ),
              ],
            ),
    );
  }
}