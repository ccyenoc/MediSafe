import 'package:flutter/material.dart';
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
            print("Notification pressed");
          },
          icon: const Icon(Icons.notifications_none, color: AppColors.white, size: 28),
          tooltip: 'Notifications',
        ),
        const SizedBox(width: 10),
        // Settings Icon
        IconButton(
          onPressed: () {
            print("Settings pressed");
          },
          icon: const Icon(Icons.settings_outlined, color: AppColors.white, size: 28),
          tooltip: 'Settings',
        ),
      ],
    );
  }
}