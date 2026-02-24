import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:medisafe/screens/notification_page.dart';
import 'package:medisafe/screens/settings_page.dart';
import '../colors/color.dart';

class HeaderActions extends StatelessWidget {
  const HeaderActions({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Notification bell with live badge
        StreamBuilder<QuerySnapshot>(
          stream: user == null
              ? const Stream.empty()
              : FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('schedules')
                  .where('isActive', isEqualTo: true)
                  .where('isTaken', isEqualTo: false)
                  .where('time',
                      isGreaterThanOrEqualTo:
                          Timestamp.fromDate(DateTime.now()))
                  .where('time',
                      isLessThan: Timestamp.fromDate(DateTime(
                        DateTime.now().year,
                        DateTime.now().month,
                        DateTime.now().day + 1,
                      )))
                  .snapshots(),
          builder: (context, snapshot) {
            final count = snapshot.data?.docs.length ?? 0;

            return Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const NotificationPage()),
                    );
                  },
                  icon: const Icon(Icons.notifications_none,
                      color: AppColors.white, size: 28),
                  tooltip: 'Notifications',
                ),
                if (count > 0)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        count > 9 ? '9+' : '$count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(width: 4),
        // Settings icon
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            );
          },
          icon: const Icon(Icons.settings_outlined,
              color: AppColors.white, size: 28),
          tooltip: 'Settings',
        ),
      ],
    );
  }
}