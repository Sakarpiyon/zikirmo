// lib/core/models/user_zikir_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// Kullanıcının zikir geçmişini ve ilerlemesini takip eden model
class UserZikirModel {
  final String id;
  final String userId;
  final String zikirId;
  final int currentCount; // Mevcut sayım
  final int targetCount; // Hedef sayım
  final bool isCompleted; // Tamamlandı mı?
  final DateTime createdAt; // Oluşturulma tarihi
  final DateTime updatedAt; // Son güncellenme tarihi
  final DateTime? completedAt; // Tamamlanma tarihi
  final Duration? timeSpent; // Harcanan süre
  final List<ZikirSession> sessions; // Zikir oturumları
  final Map<String, dynamic>? metadata; // Ek bilgiler

  UserZikirModel({
    required this.id,
    required this.userId,
    required this.zikirId,
    required this.currentCount,
    required this.targetCount,
    required this.createdAt,
    required this.updatedAt,
    this.isCompleted = false,
    this.completedAt,
    this.timeSpent,
    this.sessions = const [],
    this.metadata,
  });

  /// Firestore dokümanından UserZikirModel oluşturur
  factory UserZikirModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return UserZikirModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      zikirId: data['zikirId'] ?? '',
      currentCount: data['currentCount'] ?? 0,
      targetCount: data['targetCount'] ?? 33,
      isCompleted: data['isCompleted'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      timeSpent: data['timeSpentSeconds'] != null 
          ? Duration(seconds: data['timeSpentSeconds']) 
          : null,
      sessions: (data['sessions'] as List<dynamic>?)
              ?.map((session) => ZikirSession.fromMap(session))
              .toList() ?? [],
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Map'ten UserZikirModel oluşturur
  factory UserZikirModel.fromMap(Map<String, dynamic> data) {
    return UserZikirModel(
      id: data['id'] ?? '',
      userId: data['userId'] ?? '',
      zikirId: data['zikirId'] ?? '',
      currentCount: data['currentCount'] ?? 0,
      targetCount: data['targetCount'] ?? 33,
      isCompleted: data['isCompleted'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      timeSpent: data['timeSpentSeconds'] != null 
          ? Duration(seconds: data['timeSpentSeconds']) 
          : null,
      sessions: (data['sessions'] as List<dynamic>?)
              ?.map((session) => ZikirSession.fromMap(session))
              .toList() ?? [],
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  /// JSON'dan UserZikirModel oluşturur (Firebase Functions için)
  factory UserZikirModel.fromJson(Map<String, dynamic> json) {
    return UserZikirModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      zikirId: json['zikirId'] ?? '',
      currentCount: json['currentCount'] ?? 0,
      targetCount: json['targetCount'] ?? 33,
      isCompleted: json['isCompleted'] ?? false,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : DateTime.now(),
      completedAt: json['completedAt'] != null 
          ? DateTime.parse(json['completedAt']) 
          : null,
      timeSpent: json['timeSpentSeconds'] != null 
          ? Duration(seconds: json['timeSpentSeconds']) 
          : null,
      sessions: (json['sessions'] as List<dynamic>?)
              ?.map((session) => ZikirSession.fromMap(session))
              .toList() ?? [],
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// UserZikirModel'i Map'e dönüştürür (Firestore için)
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'zikirId': zikirId,
      'currentCount': currentCount,
      'targetCount': targetCount,
      'isCompleted': isCompleted,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'timeSpentSeconds': timeSpent?.inSeconds,
      'sessions': sessions.map((session) => session.toMap()).toList(),
      'metadata': metadata,
    };
  }

  /// UserZikirModel'i JSON'a dönüştürür
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'zikirId': zikirId,
      'currentCount': currentCount,
      'targetCount': targetCount,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'timeSpentSeconds': timeSpent?.inSeconds,
      'sessions': sessions.map((session) => session.toMap()).toList(),
      'metadata': metadata,
    };
  }

  /// UserZikirModel'in bir kopyasını oluşturur
  UserZikirModel copyWith({
    String? id,
    String? userId,
    String? zikirId,
    int? currentCount,
    int? targetCount,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
    Duration? timeSpent,
    List<ZikirSession>? sessions,
    Map<String, dynamic>? metadata,
  }) {
    return UserZikirModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      zikirId: zikirId ?? this.zikirId,
      currentCount: currentCount ?? this.currentCount,
      targetCount: targetCount ?? this.targetCount,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
      timeSpent: timeSpent ?? this.timeSpent,
      sessions: sessions ?? this.sessions,
      metadata: metadata ?? this.metadata,
    );
  }

  /// İlerleme yüzdesini hesaplar (0.0 - 1.0 arası)
  double get progressPercentage {
    if (targetCount <= 0) return 0.0;
    return (currentCount / targetCount).clamp(0.0, 1.0);
  }

  /// Kalan sayıyı hesaplar
  int get remainingCount {
    return (targetCount - currentCount).clamp(0, targetCount);
  }

  /// Hedefi aştı mı kontrol eder
  bool get isOverTarget => currentCount > targetCount;

  /// Bugün tamamlandı mı kontrol eder
  bool get isCompletedToday {
    if (!isCompleted || completedAt == null) return false;
    final now = DateTime.now();
    final completed = completedAt!;
    return now.year == completed.year &&
           now.month == completed.month &&
           now.day == completed.day;
  }

  /// Ortalama hızı hesaplar (dakika başına zikir)
  double get averageSpeed {
    if (timeSpent == null || timeSpent!.inMinutes <= 0) return 0.0;
    return currentCount / timeSpent!.inMinutes;
  }

  /// Son oturumu alır
  ZikirSession? get lastSession {
    if (sessions.isEmpty) return null;
    return sessions.last;
  }

  /// Toplam oturum sayısını alır
  int get totalSessions => sessions.length;

  /// En uzun oturumu alır
  ZikirSession? get longestSession {
    if (sessions.isEmpty) return null;
    return sessions.reduce((a, b) => 
        a.duration.inSeconds > b.duration.inSeconds ? a : b);
  }

  @override
  String toString() {
    return 'UserZikirModel(id: $id, userId: $userId, zikirId: $zikirId, currentCount: $currentCount/$targetCount, isCompleted: $isCompleted)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserZikirModel &&
        other.id == id &&
        other.userId == userId &&
        other.zikirId == zikirId;
  }

  @override
  int get hashCode {
    return id.hashCode ^ userId.hashCode ^ zikirId.hashCode;
  }
}

/// Zikir oturumunu temsil eden model
class ZikirSession {
  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final int count; // Bu oturumda çekilen zikir sayısı
  final Duration duration; // Oturum süresi
  final Map<String, dynamic>? metadata; // Ek bilgiler

  ZikirSession({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.count,
    required this.duration,
    this.metadata,
  });

  /// Map'ten ZikirSession oluşturur
  factory ZikirSession.fromMap(Map<String, dynamic> data) {
    final startTime = (data['startTime'] as Timestamp?)?.toDate() ?? DateTime.now();
    final endTime = (data['endTime'] as Timestamp?)?.toDate() ?? DateTime.now();
    
    return ZikirSession(
      id: data['id'] ?? '',
      startTime: startTime,
      endTime: endTime,
      count: data['count'] ?? 0,
      duration: Duration(seconds: data['durationSeconds'] ?? endTime.difference(startTime).inSeconds),
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  /// ZikirSession'ı Map'e dönüştürür
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'count': count,
      'durationSeconds': duration.inSeconds,
      'metadata': metadata,
    };
  }

  /// Yeni bir oturum oluşturur
  static ZikirSession create({
    required DateTime startTime,
    required DateTime endTime,
    required int count,
    Map<String, dynamic>? metadata,
  }) {
    return ZikirSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      startTime: startTime,
      endTime: endTime,
      count: count,
      duration: endTime.difference(startTime),
      metadata: metadata,
    );
  }

  /// Oturum hızını hesaplar (dakika başına zikir)
  double get speed {
    if (duration.inMinutes <= 0) return 0.0;
    return count / duration.inMinutes;
  }

  /// Oturumun bugün olup olmadığını kontrol eder
  bool get isToday {
    final now = DateTime.now();
    return now.year == startTime.year &&
           now.month == startTime.month &&
           now.day == startTime.day;
  }

  @override
  String toString() {
    return 'ZikirSession(id: $id, startTime: $startTime, endTime: $endTime, count: $count, duration: $duration)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ZikirSession &&
        other.id == id &&
        other.startTime == startTime &&
        other.endTime == endTime;
  }

  @override
  int get hashCode {
    return id.hashCode ^ startTime.hashCode ^ endTime.hashCode;
  }
}