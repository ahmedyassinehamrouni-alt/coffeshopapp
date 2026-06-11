import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'menu_item_model.freezed.dart';
part 'menu_item_model.g.dart';

// ── Category enum ─────────────────────────────────────────────────────────────

enum MenuCategory {
  hotDrinks,
  coldDrinks,
  food,
  desserts,
  extras;

  String get displayName => switch (this) {
        MenuCategory.hotDrinks => 'Hot Drinks',
        MenuCategory.coldDrinks => 'Cold Drinks',
        MenuCategory.food => 'Food',
        MenuCategory.desserts => 'Desserts',
        MenuCategory.extras => 'Extras',
      };

  IconData get icon => switch (this) {
        MenuCategory.hotDrinks => Icons.coffee_outlined,
        MenuCategory.coldDrinks => Icons.local_drink_outlined,
        MenuCategory.food => Icons.lunch_dining_outlined,
        MenuCategory.desserts => Icons.cake_outlined,
        MenuCategory.extras => Icons.add_circle_outline,
      };

  static MenuCategory fromString(String v) => MenuCategory.values.firstWhere(
        (e) => e.name == v,
        orElse: () => MenuCategory.food,
      );
}

// ── Model ─────────────────────────────────────────────────────────────────────

@freezed
abstract class MenuItemModel with _$MenuItemModel {
  const MenuItemModel._();
  const factory MenuItemModel({
    required String id,
    required String name,
    required double price,
    required MenuCategory category,
    @Default('') String description,
    @Default(true) bool isAvailable,
    String? imageUrl,
    @Default(5) int preparationTimeMin,
  }) = _MenuItemModel;

  factory MenuItemModel.fromJson(Map<String, dynamic> json) =>
      _$MenuItemModelFromJson(json);

  factory MenuItemModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return MenuItemModel(
      id: doc.id,
      name: d['name'] as String,
      price: (d['price'] as num).toDouble(),
      category: MenuCategory.fromString(d['category'] as String),
      description: d['description'] as String? ?? '',
      isAvailable: d['isAvailable'] as bool? ?? true,
      imageUrl: d['imageUrl'] as String?,
      preparationTimeMin: (d['preparationTimeMin'] as num?)?.toInt() ?? 5,
    );
  }
}

extension MenuItemModelX on MenuItemModel {
  Map<String, dynamic> toFirestore() => {
        'name': name,
        'price': price,
        'category': category.name,
        'description': description,
        'isAvailable': isAvailable,
        'imageUrl': imageUrl,
        'preparationTimeMin': preparationTimeMin,
      };
}
