import 'package:flutter/material.dart';
import '../colors/color.dart';

class ChatbotButton extends StatelessWidget {
  final VoidCallback onPressed;

  const ChatbotButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: AppColors.white,
      shape: const CircleBorder(side: BorderSide(color: Colors.transparent)),
      elevation: 4,
      child: ClipOval(
        child: Image.asset(
          'assets/images/chatbot_logo.png',
          fit: BoxFit.cover, 
          width: double.infinity,
          height: double.infinity,
        ),
      ),
    );
  }
}