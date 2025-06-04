import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String nickname;
  final String email;
  final bool isEmailVerified;
  final int totalZikirCount;
  final String createdAt;
  final bool isPremium;
  final List<String> friends;
  final int points;
  final String level;
  final int currentStreak;
  final int? longestStreak;
  final List<String> badges;
  final DateTime? lastActivity;
  final Map<String, dynamic>? customClaims;
  final List<String>? purchasedThemes;
  final List<String>? purchasedAvatars;
  final List<String>? purchasedRingtones;
  final String? aboutMe;
  final Map<String, String>? socialLinks;
  final String? profileImageUrl;
  final int? dailyZikirTarget;

  UserModel({
    required this.id,
    required this.nickname,
    required this.email,
    required this.isEmailVerified,
    required this.totalZikirCount,
    required this.createdAt,
    required this.isPremium,
    this.friends = const [],
    this.points = 0,
    this.level = 'levelBeginner',
    this.currentStreak = 0,
    this.longestStreak,
    this.badges = const [],
    this.lastActivity,
    this.customClaims,
    this.purchasedThemes = const [],
    this.purchasedAvatars = const [],
    this.purchasedRingtones = const [],
    this.aboutMe,
    this.socialLinks,
    this.profileImageUrl,
    this.dailyZikirTarget,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, String id) {
    return UserModel(
      id: id,
      nickname: json['nickname'] ?? '',
      email: json['email'] ?? '',
      isEmailVerified: json['isEmailVerified'] ?? false,
      totalZikirCount: json['totalZikirCount'] ?? 0,
      createdAt: json['createdAt'] ?? '',
      isPremium: json['isPremium'] ?? false,
      friends: List<String>.from(json['friends'] ?? []),
      points: json['points'] ?? 0,
      level: json['level'] ?? 'levelBeginner',
      currentStreak: json['currentStreak'] ?? 0,
      longestStreak: json['longestStreak'],
      badges: List<String>.from(json['badges'] ?? []),
      lastActivity: (json['lastActivity'] as Timestamp?)?.toDate(),
      customClaims: json['customClaims'],
      purchasedThemes: List<String>.from(json['purchasedThemes'] ?? []),
      purchasedAvatars: List<String>.from(json['purchasedAvatars'] ?? []),
      purchasedRingtones: List<String>.from(json['purchasedRingtones'] ?? []),
      aboutMe: json['aboutMe'],
      socialLinks: json['socialLinks'] != null 
          ? Map<String, String>.from(json['socialLinks']) 
          : null,
      profileImageUrl: json['profileImageUrl'],
      dailyZikirTarget: json['dailyZikirTarget'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nickname': nickname,
      'email': email,
      'isEmailVerified': isEmailVerified,
      'totalZikirCount': totalZikirCount,
      'createdAt': createdAt,
      'isPremium': isPremium,
      'friends': friends,
      'points': points,
      'level': level,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'badges': badges,
      'lastActivity': lastActivity != null ? Timestamp.fromDate(lastActivity!) : null,
      'customClaims': customClaims,
      'purchasedThemes': purchasedThemes,
      'purchasedAvatars': purchasedAvatars,
      'purchasedRingtones': purchasedRingtones,
      'aboutMe': aboutMe,
      'socialLinks': socialLinks,
      'profileImageUrl': profileImageUrl,
      'dailyZikirTarget': dailyZikirTarget,
    };
  }

  UserModel copyWith({
    String? id,
    String? nickname,
    String? email,
    bool? isEmailVerified,
    int? totalZikirCount,
    String? createdAt,
    bool? isPremium,
    List<String>? friends,
    int? points,
    String? level,
    int? currentStreak,
    int? longestStreak,
    List<String>? badges,
    DateTime? lastActivity,
    Map<String, dynamic>? customClaims,
    List<String>? purchasedThemes,
    List<String>? purchasedAvatars,
    List<String>? purchasedRingtones,
    String? aboutMe,
    Map<String, String>? socialLinks,
    String? profileImageUrl,
    int? dailyZikirTarget,
  }) {
    return UserModel(
      id: id ?? this.id,
      nickname: nickname ?? this.nickname,
      email: email ?? this.email,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      totalZikirCount: totalZikirCount ?? this.totalZikirCount,
      createdAt: createdAt ?? this.createdAt,
      isPremium: isPremium ?? this.isPremium,
      friends: friends ?? this.friends,
      points: points ?? this.points,
      level: level ?? this.level,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      badges: badges ?? this.badges,
      lastActivity: lastActivity ?? this.lastActivity,
      customClaims: customClaims ?? this.customClaims,
      purchasedThemes: purchasedThemes ?? this.purchasedThemes,
      purchasedAvatars: purchasedAvatars ?? this.purchasedAvatars,
      purchasedRingtones: purchasedRingtones ?? this.purchasedRingtones,
      aboutMe: aboutMe ?? this.aboutMe,
      socialLinks: socialLinks ?? this.socialLinks,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      dailyZikirTarget: dailyZikirTarget ?? this.dailyZikirTarget,
    );
  }

  // Kullanıcının belirli bir rozete sahip olup olmadığını kontrol eder
  bool hasBadge(String badgeId) {
    return badges.contains(badgeId);
  }

  // Freemium kullanıcı için arkadaş limitini kontrol eder
  bool canAddMoreFriends() {
    if (isPremium) return true; // Premium kullanıcılar için sınırsız
    return friends.length < 20; // Freemium için 20 arkadaş limiti
  }
}