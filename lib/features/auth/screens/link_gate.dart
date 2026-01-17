import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';

class LinkGate extends StatelessWidget {
  const LinkGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('رابط الشريك'),
        backgroundColor: AppConstants.primaryColor,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.favorite_border,
              size: 80,
              color: AppConstants.primaryColor,
            ),
            const SizedBox(height: 20),
            const Text(
              'مرحباً بك في تطبيق عشاق',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'سيتم إضافة نظام ربط الشريك قريباً',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              child: const Text('العودة'),
            ),
          ],
        ),
      ),
    );
  }
}
