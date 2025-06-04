// lib/core/models/zikir_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class ZikirModel {
  final String id;
  final Map<String, String> title;
  final Map<String, String> description;
  final String categoryId;
  final int targetCount;
  final Map<String, String> purpose;
  final DateTime createdAt;
  final String createdBy;
  final String? arabicText;
  final String? transliteration;
  final String? audioUrlArabic;
  final String? audioUrlTranslated;
  final String? source;
  final bool isPersonal;
  final int popularity;

  ZikirModel({
    required this.id,
    required this.title,
    required this.description,
    required this.categoryId,
    required this.targetCount,
    required this.purpose,
    required this.createdAt,
    required this.createdBy,
    this.arabicText,
    this.transliteration,
    this.audioUrlArabic,
    this.audioUrlTranslated,
    this.source,
    this.isPersonal = false,
    this.popularity = 0,
  });

  factory ZikirModel.fromMap(String id, Map<String, dynamic> data) {
    return ZikirModel(
      id: id,
      title: Map<String, String>.from(data['title'] ?? {}),
      description: Map<String, String>.from(data['description'] ?? {}),
      categoryId: data['categoryId'] ?? '',
      targetCount: data['targetCount'] ?? data['requiredCount'] ?? 33, // Geriye dönük uyumluluk
      purpose: Map<String, String>.from(data['purpose'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'] ?? '',
      arabicText: data['arabicText'],
      transliteration: data['transliteration'],
      audioUrlArabic: data['audioUrlArabic'],
      audioUrlTranslated: data['audioUrlTranslated'],
      source: data['source'],
      isPersonal: data['isPersonal'] ?? false,
      popularity: data['popularity'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'categoryId': categoryId,
      'targetCount': targetCount,
      'purpose': purpose,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'arabicText': arabicText,
      'transliteration': transliteration,
      'audioUrlArabic': audioUrlArabic,
      'audioUrlTranslated': audioUrlTranslated,
      'source': source,
      'isPersonal': isPersonal,
      'popularity': popularity,
    };
  }

  String getLocalizedTitle(String languageCode) {
    return title[languageCode] ?? title['en'] ?? title.values.first;
  }

  String getLocalizedDescription(String languageCode) {
    return description[languageCode] ?? description['en'] ?? description.values.first;
  }

  String getLocalizedPurpose(String languageCode) {
    return purpose[languageCode] ?? purpose['en'] ?? purpose.values.first;
  }

  ZikirModel copyWith({
    String? id,
    Map<String, String>? title,
    Map<String, String>? description,
    String? categoryId,
    int? targetCount,
    Map<String, String>? purpose,
    DateTime? createdAt,
    String? createdBy,
    String? arabicText,
    String? transliteration,
    String? audioUrlArabic,
    String? audioUrlTranslated,
    String? source,
    bool? isPersonal,
    int? popularity,
  }) {
    return ZikirModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      targetCount: targetCount ?? this.targetCount,
      purpose: purpose ?? this.purpose,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      arabicText: arabicText ?? this.arabicText,
      transliteration: transliteration ?? this.transliteration,
      audioUrlArabic: audioUrlArabic ?? this.audioUrlArabic,
      audioUrlTranslated: audioUrlTranslated ?? this.audioUrlTranslated,
      source: source ?? this.source,
      isPersonal: isPersonal ?? this.isPersonal,
      popularity: popularity ?? this.popularity,
    );
  }
}