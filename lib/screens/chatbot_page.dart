import 'package:flutter/material.dart';
import '../colors/color.dart';
import '../models/medicine_model.dart';
import '../services/gemini_service.dart';
import '../widgets/bottom_nav.dart';

class Message {
  final String text;
  final bool isUser;
  Message({required this.text, required this.isUser});
}

class ChatbotPage extends StatefulWidget {
  final MedicineModel? medicine;
  final GeminiService? geminiService;

  const ChatbotPage({super.key, this.medicine, this.geminiService});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final TextEditingController _messageController = TextEditingController();
  final List<Message> _messages = [];
  bool _isTyping = false;
  late final GeminiService _geminiService;

  @override
  void initState() {
    super.initState();
    // Use passed-in service (already primed from result page) or create a fresh one
    _geminiService = widget.geminiService ?? GeminiService();
    if (widget.geminiService == null) {
      // General chat — no medicine context
      _geminiService.startChatSession();
    }
  }

  Future<void> _handleSend() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(Message(text: text, isUser: true));
      _isTyping = true;
      _messageController.clear();
    });

    try {
      final reply = await _geminiService.sendMessage(text);
      if (mounted) {
        setState(() => _messages.add(Message(text: reply, isUser: false)));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _messages.add(Message(
            text: "Sorry, I couldn't process that. Please try again.",
            isUser: false)));
      }
    } finally {
      if (mounted) setState(() => _isTyping = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: _buildDrawer(),
      appBar: AppBar(
        backgroundColor: AppColors.royalBlue,
        elevation: 0,
        title: Text(
          widget.medicine != null ? widget.medicine!.name : "MediSafe",
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          _buildRecentHistoryHeader(),
          Expanded(
            child: Stack(
              children: [
                ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    return _buildChatBubble(msg.text, msg.isUser);
                  },
                ),
                if (_messages.isEmpty) _buildWelcomeBubble(),
                if (_isTyping) _buildTypingIndicator(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: widget.medicine != null
                    ? "Ask about ${widget.medicine!.name}..."
                    : "Ask MediSafe...",
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
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
                        icon: const Icon(Icons.send, color: AppColors.royalBlue),
                        onPressed: _handleSend,
                      ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: AppColors.royalBlue),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide:
                      const BorderSide(color: AppColors.royalBlue, width: 2),
                ),
              ),
              onSubmitted: (_) => _handleSend(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const MedicalBottomNav(),
    );
  }

  Widget _buildChatBubble(String text, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.all(15),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser ? AppColors.red50 : AppColors.royalBlue,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 20),
          ),
        ),
        child: Text(text,
            style: const TextStyle(color: Colors.white, fontSize: 14)),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.bottomLeft,
      child: Container(
        margin: const EdgeInsets.only(left: 16, bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: const BoxDecoration(
          color: AppColors.royalBlue,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        child: const Text("MediSafe is thinking...",
            style: TextStyle(color: Colors.white, fontSize: 13)),
      ),
    );
  }

  Widget _buildDrawer() => Drawer(
        child: Column(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: AppColors.royalBlue),
              child: Center(
                  child: Text("Chat History",
                      style: TextStyle(color: Colors.white, fontSize: 20))),
            ),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text("New Chat"),
              onTap: () {
                setState(() => _messages.clear());
                _geminiService.startChatSession();
                Navigator.pop(context);
              },
            ),
            const Divider(),
            const Expanded(
                child: Center(
                    child: Text("No history yet",
                        style: TextStyle(color: Colors.grey)))),
          ],
        ),
      );

  Widget _buildRecentHistoryHeader() => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Recent Chat History",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              height: 80,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.royalBlue)),
              child: const Center(
                  child: Text("Empty", style: TextStyle(color: Colors.grey))),
            ),
          ],
        ),
      );

  Widget _buildWelcomeBubble() => Align(
        alignment: Alignment.topLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          padding: const EdgeInsets.all(15),
          decoration: const BoxDecoration(
            color: AppColors.royalBlue,
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20)),
          ),
          child: Text(
            widget.medicine != null
                ? "Hi! I know all about ${widget.medicine!.name}. Ask me anything!"
                : "Hi, I am MediSafe. Your\nMedicine Companion.",
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
      );
}