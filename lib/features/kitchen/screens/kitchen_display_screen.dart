import 'package:flutter/material.dart';
import '../../../core/constants/app_strings.dart';

class KitchenDisplayScreen extends StatelessWidget {
  const KitchenDisplayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.kitchen)),
      body: const Center(child: Text('Kitchen display — coming next')),
    );
  }
}
