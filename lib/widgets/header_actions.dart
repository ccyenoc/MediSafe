import 'package:flutter/material.dart';
import 'package:medisafe/screens/notification_page.dart';
import 'package:medisafe/screens/settings_page.dart';
import '../colors/color.dart';

class HeaderActions extends StatelessWidget {
  const HeaderActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Notification Icon
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const NotificationPage()),
            );
          },
          icon: const Icon(Icons.notifications_none, color: AppColors.white, size: 28),
          tooltip: 'Notifications',
        ),
        const SizedBox(width: 10),
        // Settings Icon
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsPage()),
            );
          },
          icon: const Icon(Icons.settings_outlined, color: AppColors.white, size: 28),
          tooltip: 'Settings',
        ),
      ],
    );
  }
}