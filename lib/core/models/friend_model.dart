import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Arkadaşlık istekleri ve durumlarını yönetmek için kullanılan model
class FriendModel {
  final String id;
  final String requesterId; // İstek gönderen kullanıcının ID'si
  final String receiverId; // İstek alan kullanıcının ID'si
  final FriendRequestStatus status; // İsteğin durumu
  final DateTime createdAt; // İsteğin gönderilme tarihi
  final DateTime? updatedAt; // İsteğin güncellenme tarihi
  final Map<String, dynamic>? metadata; // Ek bilgiler

  FriendModel({
    required this.id,
    required this.requesterId,
    required this.receiverId,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.metadata,
  });

  /// Firestore dokümanından FriendModel oluşturur
  factory FriendModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return FriendModel(
      id: doc.id,
      requesterId: data['requesterId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      status: FriendRequestStatus.fromString(data['status'] ?? 'pending'),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Map'ten FriendModel oluşturur
  factory FriendModel.fromMap(Map<String, dynamic> data, String id) {
    return FriendModel(
      id: id,
      requesterId: data['requesterId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      status: FriendRequestStatus.fromString(data['status'] ?? 'pending'),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  /// FriendModel'i Map'e dönüştürür (Firestore için)
  Map<String, dynamic> toMap() {
    return {
      'requesterId': requesterId,
      'receiverId': receiverId,
      'status': status.toString(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'metadata': metadata,
    };
  }

  /// FriendModel'in bir kopyasını oluşturur
  FriendModel copyWith({
    String? id,
    String? requesterId,
    String? receiverId,
    FriendRequestStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return FriendModel(
      id: id ?? this.id,
      requesterId: requesterId ?? this.requesterId,
      receiverId: receiverId ?? this.receiverId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Arkadaşlık isteğinin engellenip engellenmediğini kontrol eder
  bool get isBlocked => status == FriendRequestStatus.blocked;

  /// Arkadaşlık isteğinin beklemede olup olmadığını kontrol eder
  bool get isPending => status == FriendRequestStatus.pending;

  /// Arkadaşlık isteğinin kabul edilip edilmediğini kontrol eder
  bool get isAccepted => status == FriendRequestStatus.accepted;

  /// Arkadaşlık isteğinin reddedilip edilmediğini kontrol eder
  bool get isRejected => status == FriendRequestStatus.rejected;

  /// İsteğin ne kadar süre önce gönderildiğini hesaplar
  Duration get timeAgo => DateTime.now().difference(createdAt);

  /// İsteğin son güncellenme zamanını alır
  DateTime get lastUpdated => updatedAt ?? createdAt;

  @override
  String toString() {
    return 'FriendModel(id: $id, requesterId: $requesterId, receiverId: $receiverId, status: $status, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is FriendModel &&
        other.id == id &&
        other.requesterId == requesterId &&
        other.receiverId == receiverId &&
        other.status == status;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        requesterId.hashCode ^
        receiverId.hashCode ^
        status.hashCode;
  }
}

/// Arkadaşlık isteği durumlarını temsil eden enum
enum FriendRequestStatus {
  pending,   // Beklemede
  accepted,  // Kabul edildi
  rejected,  // Reddedildi
  blocked,   // Engellendi
  cancelled; // İptal edildi

  /// String'den FriendRequestStatus oluşturur
  static FriendRequestStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return FriendRequestStatus.pending;
      case 'accepted':
        return FriendRequestStatus.accepted;
      case 'rejected':
        return FriendRequestStatus.rejected;
      case 'blocked':
        return FriendRequestStatus.blocked;
      case 'cancelled':
        return FriendRequestStatus.cancelled;
      default:
        return FriendRequestStatus.pending;
    }
  }

  /// FriendRequestStatus'u string'e dönüştürür
  @override
  String toString() {
    switch (this) {
      case FriendRequestStatus.pending:
        return 'pending';
      case FriendRequestStatus.accepted:
        return 'accepted';
      case FriendRequestStatus.rejected:
        return 'rejected';
      case FriendRequestStatus.blocked:
        return 'blocked';
      case FriendRequestStatus.cancelled:
        return 'cancelled';
    }
  }

  /// Durumun görüntülenecek ismini döner
  String get displayName {
    switch (this) {
      case FriendRequestStatus.pending:
        return 'Beklemede';
      case FriendRequestStatus.accepted:
        return 'Kabul Edildi';
      case FriendRequestStatus.rejected:
        return 'Reddedildi';
      case FriendRequestStatus.blocked:
        return 'Engellendi';
      case FriendRequestStatus.cancelled:
        return 'İptal Edildi';
    }
  }

  /// Durumun rengini döner
  Color get color {
    switch (this) {
      case FriendRequestStatus.pending:
        return Colors.orange;
      case FriendRequestStatus.accepted:
        return Colors.green;
      case FriendRequestStatus.rejected:
        return Colors.red;
      case FriendRequestStatus.blocked:
        return Colors.red.shade800;
      case FriendRequestStatus.cancelled:
        return Colors.grey;
    }
  }
}

/// Arkadaşlık listesi için basit bir model
class FriendshipModel {
  final String userId;
  final String friendId;
  final DateTime createdAt;
  final bool isActive;
  final Map<String, dynamic>? metadata;

  FriendshipModel({
    required this.userId,
    required this.friendId,
    required this.createdAt,
    this.isActive = true,
    this.metadata,
  });

  /// Firestore dokümanından FriendshipModel oluşturur
  factory FriendshipModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return FriendshipModel(
      userId: data['userId'] ?? '',
      friendId: data['friendId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Map'ten FriendshipModel oluşturur
  factory FriendshipModel.fromMap(Map<String, dynamic> data) {
    return FriendshipModel(
      userId: data['userId'] ?? '',
      friendId: data['friendId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  /// FriendshipModel'i Map'e dönüştürür
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'friendId': friendId,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
      'metadata': metadata,
    };
  }

  /// FriendshipModel'in bir kopyasını oluşturur
  FriendshipModel copyWith({
    String? userId,
    String? friendId,
    DateTime? createdAt,
    bool? isActive,
    Map<String, dynamic>? metadata,
  }) {
    return FriendshipModel(
      userId: userId ?? this.userId,
      friendId: friendId ?? this.friendId,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'FriendshipModel(userId: $userId, friendId: $friendId, createdAt: $createdAt, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is FriendshipModel &&
        other.userId == userId &&
        other.friendId == friendId;
  }

  @override
  int get hashCode {
    return userId.hashCode ^ friendId.hashCode;
  }
}