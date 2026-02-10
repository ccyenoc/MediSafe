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
      shape: const CircleBorder(side: BorderSide(color: AppColors.royalBlue)),
      elevation: 4,
      child: const Text(
        "chatbot",
        style: TextStyle(color: Colors.black, fontSize: 10),
      ),
    );
  }
}