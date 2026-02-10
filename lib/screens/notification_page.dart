import 'package:flutter/material.dart';
import '../colors/color.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    bool hasNotifications = false;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.royalBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Notifications",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: hasNotifications 
          ? _buildNotificationList() 
          : _buildEmptyState(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: const Color(0xFFD1E3F8), 
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.royalBlue, width: 2),
            ),
            child: const Icon(
              Icons.notifications_off_outlined,
              size: 80,
              color: AppColors.royalBlue,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "All Caught Up!",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "You have no new notifications at the moment.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationList() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 0, 
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFD1E3F8),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppColors.royalBlue),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.royalBlue),
              SizedBox(width: 12),
              Expanded(
                child: Text("Notification content goes here."),
              ),
            ],
          ),
        );
      },
    );
  }
}

