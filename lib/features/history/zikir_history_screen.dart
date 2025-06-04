// lib/features/history/zikir_history_screen.dart

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/providers.dart';
import 'package:zikirmo_new/core/services/auth_service.dart';
import 'package:zikirmo_new/core/services/firestore_service.dart';
import 'package:zikirmo_new/core/models/user_zikir_model.dart';
import 'package:zikirmo_new/core/models/zikir_model.dart';
import 'package:zikirmo_new/routes.dart';

// Zikir geçmişini getiren provider
final zikirHistoryProvider = FutureProvider.family<List<UserZikirModel>, String>((ref, period) async {
  final authService = ref.watch(authServiceProvider);
  final firestoreService = ref.watch(firestoreServiceProvider);
  final userId = authService.currentUser?.uid;
  
  if (userId == null) return [];
  
  try {
    DateTime startDate;
    final now = DateTime.now();
    
    switch (period) {
      case 'today':
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case 'week':
        startDate = now.subtract(const Duration(days: 7));
        break;
      case 'month':
        startDate = DateTime(now.year, now.month, 1);
        break;
      case 'all':
      default:
        startDate = DateTime(2020, 1, 1); // Çok eski bir tarih
        break;
    }
    
    final snapshot = await firestoreService.firestore
        .collection('user_zikirs')
        .where('userId', isEqualTo: userId)
        .where('createdAt', isGreaterThanOrEqualTo: startDate)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .get();
    
    return snapshot.docs
        .map((doc) => UserZikirModel.fromFirestore(doc))
        .toList();
  } catch (e) {
    return [];
  }
});

// Zikir detaylarını getiren provider
final zikirDetailsProvider = FutureProvider.family<ZikirModel?, String>((ref, zikirId) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return await firestoreService.getZikir(zikirId);
});

class ZikirHistoryScreen extends ConsumerStatefulWidget {
  const ZikirHistoryScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ZikirHistoryScreen> createState() => _ZikirHistoryScreenState();
}

class _ZikirHistoryScreenState extends ConsumerState<ZikirHistoryScreen> {
  String _selectedPeriod = 'all';
  
  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(zikirHistoryProvider(_selectedPeriod));
    
    return Scaffold(
      appBar: AppBar(
        title: Text('zikirHistory'.tr()),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _selectedPeriod = value;
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'today', child: Text('today'.tr())),
              PopupMenuItem(value: 'week', child: Text('thisWeek'.tr())),
              PopupMenuItem(value: 'month', child: Text('thisMonth'.tr())),
              PopupMenuItem(value: 'all', child: Text('all'.tr())),
            ],
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_getPeriodDisplayName(_selectedPeriod)),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
        ],
      ),
      body: historyAsync.when(
        data: (history) {
          if (history.isEmpty) {
            return _buildEmptyState();
          }
          
          return RefreshIndicator(
            onRefresh: () async {
              ref.refresh(zikirHistoryProvider(_selectedPeriod));
            },
            child: Column(
              children: [
                // İstatistik kartı
                _buildStatsCard(history),
                
                // Geçmiş listesi
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: history.length,
                    itemBuilder: (context, index) {
                      final userZikir = history[index];
                      return _buildHistoryItem(userZikir);
                    },
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(),
      ),
    );
  }
  
  // İstatistik kartı
  Widget _buildStatsCard(List<UserZikirModel> history) {
    final totalZikirs = history.fold<int>(0, (sum, item) => sum + item.currentCount);
    final completedZikirs = history.where((item) => item.isCompleted).length;
    final totalTime = history.fold<Duration>(
      Duration.zero, 
      (sum, item) => sum + (item.timeSpent ?? Duration.zero)
    );
    
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getStatsTitle(_selectedPeriod),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem('totalZikirs'.tr(), totalZikirs.toString(), Icons.auto_awesome),
                _buildStatItem('completed'.tr(), completedZikirs.toString(), Icons.check_circle),
                _buildStatItem('duration'.tr(), _formatDuration(totalTime), Icons.access_time),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  // İstatistik öğesi
  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
  
  // Geçmiş öğesi
  Widget _buildHistoryItem(UserZikirModel userZikir) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Consumer(
        builder: (context, ref, child) {
          final zikirAsync = ref.watch(zikirDetailsProvider(userZikir.zikirId));
          
          return zikirAsync.when(
            data: (zikir) => _buildHistoryTile(userZikir, zikir),
            loading: () => _buildHistoryTileLoading(),
            error: (_, __) => _buildHistoryTileError(userZikir),
          );
        },
      ),
    );
  }
  
  // Geçmiş tile'ı
  Widget _buildHistoryTile(UserZikirModel userZikir, ZikirModel? zikir) {
    final progress = userZikir.progressPercentage;
    final isCompleted = userZikir.isCompleted;
    
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isCompleted ? Colors.green.withOpacity(0.2) : Theme.of(context).primaryColor.withOpacity(0.2),
        child: Icon(
          isCompleted ? Icons.check : Icons.auto_awesome,
          color: isCompleted ? Colors.green : Theme.of(context).primaryColor,
        ),
      ),
      title: Text(
        zikir?.getLocalizedTitle(context.locale.languageCode) ?? 'unknownZikir'.tr(),
        style: TextStyle(
          fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text('${userZikir.currentCount} / ${userZikir.targetCount}'),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              isCompleted ? Colors.green : Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('dd.MM.yyyy HH:mm').format(userZikir.createdAt),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              if (userZikir.timeSpent != null)
                Text(
                  _formatDuration(userZikir.timeSpent!),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
            ],
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isCompleted)
            Icon(Icons.emoji_events, color: Colors.amber, size: 20),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(value, userZikir, zikir),
            itemBuilder: (context) => [
              if (zikir != null) ...[
                PopupMenuItem(
                  value: 'continue',
                  child: Row(
                    children: [
                      const Icon(Icons.play_arrow),
                      const SizedBox(width: 8),
                      Text('continue'.tr()),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'details',
                  child: Row(
                    children: [
                      const Icon(Icons.info),
                      const SizedBox(width: 8),
                      Text('details'.tr()),
                    ],
                  ),
                ),
              ],
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(Icons.delete, color: Colors.red),
                    const SizedBox(width: 8),
                    Text('delete'.tr(), style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  // Yükleniyor tile'ı
  Widget _buildHistoryTileLoading() {
    return ListTile(
      leading: CircleAvatar(backgroundColor: Colors.grey[300]),
      title: Container(height: 16, color: Colors.grey[300]),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Container(height: 12, width: 100, color: Colors.grey[300]),
          const SizedBox(height: 8),
          Container(height: 4, color: Colors.grey[300]),
        ],
      ),
    );
  }
  
  // Hata tile'ı
  Widget _buildHistoryTileError(UserZikirModel userZikir) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.red.withOpacity(0.2),
        child: const Icon(Icons.error, color: Colors.red),
      ),
      title: Text('zikirInfoCouldNotLoad'.tr()),
      subtitle: Text('${userZikir.currentCount} / ${userZikir.targetCount}'),
    );
  }
  
  // Menü aksiyonları
  void _handleMenuAction(String action, UserZikirModel userZikir, ZikirModel? zikir) {
    switch (action) {
      case 'continue':
        if (zikir != null) {
          Navigator.pushNamed(
            context,
            AppRoutes.zikirCounter,
            arguments: zikir.id,
          );
        }
        break;
      case 'details':
        if (zikir != null) {
          Navigator.pushNamed(
            context,
            AppRoutes.zikirDetail,
            arguments: zikir.id,
          );
        }
        break;
      case 'delete':
        _showDeleteDialog(userZikir);
        break;
    }
  }
  
  // Silme onay dialog'u
  void _showDeleteDialog(UserZikirModel userZikir) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('deleteZikirRecord'.tr()),
        content: Text('deleteZikirConfirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteZikirRecord(userZikir);
            },
            child: Text('delete'.tr(), style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
  
  // Zikir kaydını silme
  Future<void> _deleteZikirRecord(UserZikirModel userZikir) async {
    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      await firestoreService.firestore
          .collection('user_zikirs')
          .doc(userZikir.id)
          .delete();
      
      // Provider'ı yenile
      ref.refresh(zikirHistoryProvider(_selectedPeriod));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('zikirRecordDeleted'.tr())),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('deleteFailed'.tr(args: [e.toString()]))),
        );
      }
    }
  }
  
  // Boş durum
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'noZikirHistory'.tr(),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'startZikirToSeeHistory'.tr(),
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.zikirCounter);
            },
            child: Text('pullFirstZikir'.tr()),
          ),
        ],
      ),
    );
  }
  
  // Hata durumu
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'errorLoadingHistory'.tr(),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ref.refresh(zikirHistoryProvider(_selectedPeriod));
            },
            child: Text('tryAgain'.tr()),
          ),
        ],
      ),
    );
  }
  
  // Periyot görüntü adı
  String _getPeriodDisplayName(String period) {
    switch (period) {
      case 'today':
        return 'today'.tr();
      case 'week':
        return 'thisWeek'.tr();
      case 'month':
        return 'thisMonth'.tr();
      case 'all':
      default:
        return 'all'.tr();
    }
  }
  
  // İstatistik başlığı
  String _getStatsTitle(String period) {
    switch (period) {
      case 'today':
        return 'todayStats'.tr();
      case 'week':
        return 'thisWeekStats'.tr();
      case 'month':
        return 'thisMonthStats'.tr();
      case 'all':
      default:
        return 'allTimeStats'.tr();
    }
  }
  
  // Süre formatlama
  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return 'hoursMinutes'.tr(args: [duration.inHours.toString(), duration.inMinutes.remainder(60).toString()]);
    } else if (duration.inMinutes > 0) {
      return 'minutes'.tr(args: [duration.inMinutes.toString()]);
    } else {
      return 'seconds'.tr(args: [duration.inSeconds.toString()]);
    }
  }
}
  
