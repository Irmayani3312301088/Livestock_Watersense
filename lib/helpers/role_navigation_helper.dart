import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../screens/home_page.dart';
import '../screens/user_dashboard.dart';

class RoleNavigationHelper {
  static Future<void> goToDashboard(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('role');

    if (!context.mounted) return;

    if (role == 'admin') {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
        (route) => false,
      );
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const UserDashboard()),
        (route) => false,
      );
    }
  }
}
