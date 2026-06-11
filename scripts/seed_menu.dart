// Run with: dart run scripts/seed_menu.dart
// Seeds the Firestore `menuItems` collection with sample data.
// Requires GOOGLE_APPLICATION_CREDENTIALS env var or Firebase CLI login.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';

import '../lib/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final db = FirebaseFirestore.instance;
  final col = db.collection('menuItems');

  final items = [
    // ── Hot Drinks ────────────────────────────────────────────────────────
    {
      'name': 'Espresso',
      'price': 2.50,
      'category': 'hotDrinks',
      'description': 'Rich single shot of espresso.',
      'isAvailable': true,
      'preparationTimeMin': 3,
    },
    {
      'name': 'Cappuccino',
      'price': 4.00,
      'category': 'hotDrinks',
      'description': 'Espresso with steamed milk and thick foam.',
      'isAvailable': true,
      'preparationTimeMin': 5,
    },
    {
      'name': 'Flat White',
      'price': 4.00,
      'category': 'hotDrinks',
      'description': 'Double ristretto with velvety microfoam.',
      'isAvailable': true,
      'preparationTimeMin': 5,
    },
    {
      'name': 'Latte',
      'price': 4.50,
      'category': 'hotDrinks',
      'description': 'Smooth espresso and steamed milk.',
      'isAvailable': true,
      'preparationTimeMin': 5,
    },
    {
      'name': 'Americano',
      'price': 3.00,
      'category': 'hotDrinks',
      'description': 'Espresso diluted with hot water.',
      'isAvailable': true,
      'preparationTimeMin': 3,
    },
    {
      'name': 'Chai Latte',
      'price': 4.50,
      'category': 'hotDrinks',
      'description': 'Spiced chai with steamed milk.',
      'isAvailable': true,
      'preparationTimeMin': 5,
    },

    // ── Cold Drinks ───────────────────────────────────────────────────────
    {
      'name': 'Iced Latte',
      'price': 5.00,
      'category': 'coldDrinks',
      'description': 'Chilled espresso over ice with cold milk.',
      'isAvailable': true,
      'preparationTimeMin': 4,
    },
    {
      'name': 'Cold Brew',
      'price': 5.00,
      'category': 'coldDrinks',
      'description': '12-hour cold-steeped coffee, smooth and strong.',
      'isAvailable': true,
      'preparationTimeMin': 2,
    },
    {
      'name': 'Matcha Latte',
      'price': 5.50,
      'category': 'coldDrinks',
      'description': 'Ceremonial matcha with oat milk over ice.',
      'isAvailable': true,
      'preparationTimeMin': 4,
    },
    {
      'name': 'Fresh Orange Juice',
      'price': 4.00,
      'category': 'coldDrinks',
      'description': 'Freshly squeezed oranges.',
      'isAvailable': true,
      'preparationTimeMin': 3,
    },

    // ── Food ──────────────────────────────────────────────────────────────
    {
      'name': 'Avocado Toast',
      'price': 9.50,
      'category': 'food',
      'description': 'Sourdough with smashed avocado, poached egg, chilli flakes.',
      'isAvailable': true,
      'preparationTimeMin': 10,
    },
    {
      'name': 'Granola Bowl',
      'price': 8.00,
      'category': 'food',
      'description': 'House granola with Greek yogurt and seasonal fruit.',
      'isAvailable': true,
      'preparationTimeMin': 5,
    },
    {
      'name': 'Smoked Salmon Bagel',
      'price': 11.00,
      'category': 'food',
      'description': 'Cream cheese, capers, red onion on toasted bagel.',
      'isAvailable': true,
      'preparationTimeMin': 8,
    },
    {
      'name': 'Club Sandwich',
      'price': 12.00,
      'category': 'food',
      'description': 'Grilled chicken, bacon, lettuce, tomato on toasted white.',
      'isAvailable': true,
      'preparationTimeMin': 12,
    },

    // ── Desserts ──────────────────────────────────────────────────────────
    {
      'name': 'Chocolate Brownie',
      'price': 4.50,
      'category': 'desserts',
      'description': 'Warm fudgy brownie served with vanilla ice cream.',
      'isAvailable': true,
      'preparationTimeMin': 5,
    },
    {
      'name': 'Almond Croissant',
      'price': 3.50,
      'category': 'desserts',
      'description': 'Buttery croissant filled with almond cream.',
      'isAvailable': true,
      'preparationTimeMin': 2,
    },

    // ── Extras ────────────────────────────────────────────────────────────
    {
      'name': 'Extra Shot',
      'price': 0.80,
      'category': 'extras',
      'description': 'Additional espresso shot.',
      'isAvailable': true,
      'preparationTimeMin': 1,
    },
    {
      'name': 'Oat Milk',
      'price': 0.60,
      'category': 'extras',
      'description': 'Swap to oat milk.',
      'isAvailable': true,
      'preparationTimeMin': 0,
    },
    {
      'name': 'Syrup Shot',
      'price': 0.60,
      'category': 'extras',
      'description': 'Vanilla, caramel, or hazelnut.',
      'isAvailable': true,
      'preparationTimeMin': 0,
    },
  ];

  final batch = db.batch();
  for (final item in items) {
    batch.set(col.doc(), item);
  }
  await batch.commit();
  print('✅ Seeded ${items.length} menu items to Firestore.');
}
