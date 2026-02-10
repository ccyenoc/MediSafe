import 'package:flutter/material.dart';
import 'package:medisafe/screens/chatbot_page.dart';
import '../colors/color.dart';

class FloatingChatbot extends StatefulWidget {
  final List<Message> messages;
  final TextEditingController controller;
  final Function(String) onSend;

  const FloatingChatbot({
    super.key, 
    required this.messages, 
    required this.controller, 
    required this.onSend
  });

  @override
  State<FloatingChatbot> createState() => _FloatingChatbotState();
}

class _FloatingChatbotState extends State<FloatingChatbot> {
  void _sendMessage() {
    if (widget.controller.text.trim().isNotEmpty) {
      widget.onSend(widget.controller.text);
      widget.controller.clear();
      setState(() {}); 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 80),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: AppColors.royalBlue, width: 1.5),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),

            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: widget.messages.length,
                itemBuilder: (context, index) {
                  final msg = widget.messages[index];
                  return _buildChatBubble(msg.text, msg.isUser);
                },
              ),
            ),

            if (widget.messages.isEmpty) _buildWelcomeBubble(),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: TextField(
                controller: widget.controller,
                onSubmitted: (_) => _sendMessage(), 
                decoration: InputDecoration(
                  hintText: "Ask MediSafe...",
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.send, color: AppColors.royalBlue),
                    onPressed: _sendMessage,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(color: AppColors.royalBlue),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(color: AppColors.royalBlue, width: 2),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatBubble(String text, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: isUser ?  AppColors.red50: AppColors.royalBlue,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Text(text, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildWelcomeBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        padding: const EdgeInsets.all(15),
        decoration: const BoxDecoration(
          color: AppColors.royalBlue,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20), bottomRight: Radius.circular(20)),
        ),
        child: const Text("Hi, I am MediSafe. Your\nMedicine Companion.", style: TextStyle(color: Colors.white)),
      ),
    );
  }
}