// Dosya: lib/core/models/category_model.dart
// Yol: C:\src\zikirmo_new\lib\core\models\category_model.dart
// Açıklama: Eksik methodlar eklendi

import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryModel {
  final String id;
  final Map<String, String> name;
  final Map<String, String> description;
  final DateTime createdAt;
  final String iconName;
  final int orderIndex;
  final bool isActive;
  final int zikirCount;

  CategoryModel({
    required this.id,
    required this.name,
    this.description = const {},
    required this.createdAt,
    this.iconName = 'category',
    this.orderIndex = 0,
    this.isActive = true,
    this.zikirCount = 0,
  });

  factory CategoryModel.fromMap(String id, Map<String, dynamic> data) {
    return CategoryModel(
      id: id,
      name: Map<String, String>.from(data['name'] ?? {}),
      description: Map<String, String>.from(data['description'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      iconName: data['iconName'] ?? 'category',
      orderIndex: data['orderIndex'] ?? 0,
      isActive: data['isActive'] ?? true,
      zikirCount: data['zikirCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      'iconName': iconName,
      'orderIndex': orderIndex,
      'isActive': isActive,
      'zikirCount': zikirCount,
    };
  }

  String getLocalizedName(String languageCode) {
    return name[languageCode] ?? name['en'] ?? name['tr'] ?? 'Category';
  }

  String getLocalizedDescription(String languageCode) {
    return description[languageCode] ?? description['en'] ?? description['tr'] ?? '';
  }

  CategoryModel copyWith({
    String? id,
    Map<String, String>? name,
    Map<String, String>? description,
    DateTime? createdAt,
    String? iconName,
    int? orderIndex,
    bool? isActive,
    int? zikirCount,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      iconName: iconName ?? this.iconName,
      orderIndex: orderIndex ?? this.orderIndex,
      isActive: isActive ?? this.isActive,
      zikirCount: zikirCount ?? this.zikirCount,
    );
  }
}