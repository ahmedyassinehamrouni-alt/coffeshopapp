import 'package:flutter/material.dart';
import '../../../core/constants/app_strings.dart';

class MenuManagementScreen extends StatelessWidget {
  const MenuManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.menu)),
      body: const Center(child: Text('Menu management — coming next')),
    );
  }
}
