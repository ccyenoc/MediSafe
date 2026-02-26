import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:medisafe/screens/chatbot_page.dart';
import '../colors/color.dart';
import '../services/gemini_service.dart';

class FloatingChatbot extends StatefulWidget {
  final List<Message> messages;
  final TextEditingController controller;
  final GeminiService geminiService;
  final String? sessionId;

  const FloatingChatbot({
    super.key,
    required this.messages,
    required this.controller,
    required this.geminiService,
    this.sessionId,
  });

  @override
  State<FloatingChatbot> createState() => _FloatingChatbotState();
}

class _FloatingChatbotState extends State<FloatingChatbot> {
  bool _isTyping = false;
  String? _currentSessionId;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _currentSessionId = widget.sessionId;
    if (_currentSessionId != null) {
      _loadSessionMessages(_currentSessionId!);
    }
  }

  Future<void> _loadSessionMessages(String sessionId) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .collection('chat_sessions')
          .doc(sessionId)
          .collection('messages')
          .orderBy('timestamp')
          .get();
      setState(() {
        widget.messages.clear();
        for (final doc in snap.docs) {
          final data = doc.data();
          widget.messages.add(Message(
            text: data['text'] ?? '',
            isUser: data['isUser'] == true,
          ));
        }
      });
    } catch (_) {}
  }

  Future<String> _ensureSessionExists(String firstMessageText) async {
    if (_currentSessionId != null) return _currentSessionId!;

    final sessionTitle = firstMessageText.length > 40
        ? '${firstMessageText.substring(0, 40)}…'
        : firstMessageText;

    final ref = await FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .collection('chat_sessions')
        .add({
          'createdAt': FieldValue.serverTimestamp(),
          'lastUpdated': FieldValue.serverTimestamp(),
          'title': sessionTitle,
        });

    _currentSessionId = ref.id;
    return _currentSessionId!;
  }

  Future<void> _saveMessage(Message msg) async {
    if (_currentSessionId == null || _uid.isEmpty) return;
    try {
      final sessRef = FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .collection('chat_sessions')
          .doc(_currentSessionId);

      await sessRef.collection('messages').add({
        'text': msg.text,
        'isUser': msg.isUser,
        'timestamp': FieldValue.serverTimestamp(),
      });
      await sessRef.update({'lastUpdated': FieldValue.serverTimestamp()});
    } catch (_) {}
  }

  Future<void> _sendMessage() async {
    final text = widget.controller.text.trim();
    if (text.isEmpty) return;

    final userMsg = Message(text: text, isUser: true);
    setState(() {
      widget.messages.add(userMsg);
      _isTyping = true;
      widget.controller.clear();
    });

    // Ensure session exists and save user message
    await _ensureSessionExists(text);
    await _saveMessage(userMsg);

    try {
      final reply = await widget.geminiService.sendMessage(text);
      if (mounted) {
        final botMsg = Message(text: reply, isUser: false);
        setState(() => widget.messages.add(botMsg));
        await _saveMessage(botMsg);
      }
    } catch (_) {
      if (mounted) {
        final errorMsg = Message(
            text: "Sorry, I couldn't process that.", isUser: false);
        setState(() => widget.messages.add(errorMsg));
        await _saveMessage(errorMsg);
      }
    } finally {
      if (mounted) setState(() => _isTyping = false);
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
                  icon: const Icon(Icons.arrow_back,
                      color: Colors.black, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: widget.messages.length,
                    itemBuilder: (context, index) {
                      final msg = widget.messages[index];
                      return _buildChatBubble(msg.text, msg.isUser);
                    },
                  ),
                  if (widget.messages.isEmpty) _buildWelcomeBubble(),
                  if (_isTyping) _buildTypingIndicator(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: TextField(
                controller: widget.controller,
                onSubmitted: (_) => _sendMessage(),
                decoration: InputDecoration(
                  hintText: "Ask MediSafe...",
                  suffixIcon: _isTyping
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(Icons.send,
                              color: AppColors.royalBlue),
                          onPressed: _sendMessage,
                        ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide:
                        const BorderSide(color: AppColors.royalBlue),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(
                        color: AppColors.royalBlue, width: 2),
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
          color: isUser ? AppColors.red50 : AppColors.royalBlue,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Text(text, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.bottomLeft,
      child: Container(
        margin: const EdgeInsets.only(left: 16, bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: const BoxDecoration(
          color: AppColors.royalBlue,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(15),
            topRight: Radius.circular(15),
            bottomRight: Radius.circular(15),
          ),
        ),
        child: const Text("MediSafe is thinking...",
            style: TextStyle(color: Colors.white, fontSize: 12)),
      ),
    );
  }

  Widget _buildWelcomeBubble() {
    return Align(
      alignment: Alignment.topLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        padding: const EdgeInsets.all(15),
        decoration: const BoxDecoration(
          color: AppColors.royalBlue,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        child: const Text("Hi, I am MediSafe. Your\nMedicine Companion.",
            style: TextStyle(color: Colors.white)),
      ),
    );
  }
}