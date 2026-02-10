import 'package:flutter/material.dart';
import 'package:medisafe/screens/chatbot_page.dart';
import 'package:medisafe/screens/home_page.dart';
import 'package:medisafe/screens/near_me.dart';
import 'package:medisafe/screens/scan_page.dart';
import 'package:medisafe/screens/schedule_page.dart';
import 'package:medisafe/colors/color.dart';

class MedicalBottomNav extends StatelessWidget {
  const MedicalBottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: AppColors.trueNavy,
      height: 80,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 🏠 Home
          _navItem(
            icon: Icons.home,
            label: "Home",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HomePage()),
              );
            },
          ),

          // 📅 Schedule
          _navItem(
            icon: Icons.calendar_today,
            label: "Schedule",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SchedulePage()),
              );
            },
          ),

          // 📷 Scanner (center button)
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ScanPage()),
              );
            },
            borderRadius: BorderRadius.circular(100),
            child: Container(
              width: 65,
              height: 65,
              decoration: BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.royalBlue, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.qr_code_scanner,
                color: AppColors.royalBlue,
                size: 30,
              ),
            ),
          ),

          // 💬 Chatbot
          _navItem(
            icon: Icons.smart_toy,
            label: "Chatbot",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChatbotPage()),
              );
            },
          ),

          // 📍 Near Me
          _navItem(
            icon: Icons.near_me,
            label: "Near Me",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NearMePage()),
              );
            },
          ),
        ],
      ),
    );
  }

  // 🔧 Reusable icon + label
  Widget _navItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
