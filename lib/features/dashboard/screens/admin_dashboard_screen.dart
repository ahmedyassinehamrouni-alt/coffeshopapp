import 'package:flutter/material.dart';
import '../../../core/constants/app_strings.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.dashboard)),
      body: const Center(child: Text('Admin dashboard — coming next')),
    );
  }
}
