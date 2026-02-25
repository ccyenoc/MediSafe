import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../colors/color.dart';
import '../models/medicine_model.dart';
import '../models/user_profile_model.dart';
import '../services/firestore_service.dart';
import '../services/gemini_service.dart';
import '../widgets/bottom_nav.dart';

class Message {
  final String text;
  final bool isUser;
  Message({required this.text, required this.isUser});
}

class ChatbotPage extends StatefulWidget {
  final MedicineModel? medicine; // null = generic chat
  final String? sessionId;       // null = new session

  const ChatbotPage({super.key, this.medicine, this.sessionId});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GeminiService _gemini = GeminiService();
  final List<Message> _messages = [];
  String? _currentSessionId;
  bool _isTyping = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _initSession();
  }

  Future<void> _initSession() async {
    // Load user profile for personalised AI
    UserProfileModel? profile;
    try {
      final data = await FirestoreService().getUserProfileOnce();
      if (data != null) profile = UserProfileModel.fromFirestore(data);
    } catch (_) {}

    if (widget.sessionId != null) {
      // ── Resume existing saved session ──
      _currentSessionId = widget.sessionId;
      await _loadSessionMessages(widget.sessionId!);

      // Re-create Gemini session with medicine context if available
      MedicineModel? medicine;
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(_uid)
            .collection('chat_sessions')
            .doc(widget.sessionId)
            .get();
        if (doc.exists) {
          final data = doc.data()!;
          if (data['medicineName'] != null) {
            // best-effort reconstruct minimal context
            medicine = MedicineModel(
              name: data['medicineName'] ?? '',
              shortDescription: '',
              function: data['medicineFunction'] ?? '',
              dosage: data['medicineDosage'] ?? '',
              sideEffects: List<String>.from(data['medicineSideEffects'] ?? []),
              recipients: [],
              contraindications: [],
              allergies: List<String>.from(data['medicineAllergies'] ?? []),
            );
          }
        }
      } catch (_) {}
      _gemini.startChatSession(medicine: medicine, profile: profile);
    } else {
      // ── Start a fresh session ──
      _gemini.startChatSession(medicine: widget.medicine, profile: profile);
      _currentSessionId = null; // will be created on first message
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
        _messages.clear();
        for (final doc in snap.docs) {
          final data = doc.data();
          _messages.add(Message(
            text: data['text'] ?? '',
            isUser: data['isUser'] == true,
          ));
        }
      });
      _scrollToBottom();
    } catch (_) {}
  }

  Future<String> _ensureSessionExists(String firstMessageText) async {
    if (_currentSessionId != null) return _currentSessionId!;

    final sessionTitle = widget.medicine != null
        ? widget.medicine!.name
        : (firstMessageText.length > 40
            ? '${firstMessageText.substring(0, 40)}…'
            : firstMessageText);

    final sessionData = <String, dynamic>{
      'createdAt': FieldValue.serverTimestamp(),
      'lastUpdated': FieldValue.serverTimestamp(),
      'title': sessionTitle,
    };

    if (widget.medicine != null) {
      sessionData['medicineName'] = widget.medicine!.name;
      sessionData['medicineFunction'] = widget.medicine!.function;
      sessionData['medicineDosage'] = widget.medicine!.dosage;
      sessionData['medicineSideEffects'] = widget.medicine!.sideEffects;
      sessionData['medicineAllergies'] = widget.medicine!.allergies;
    }

    final ref = await FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .collection('chat_sessions')
        .add(sessionData);

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

  Future<void> _handleSend() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isTyping) return;

    final userMsg = Message(text: text, isUser: true);
    setState(() {
      _messages.add(userMsg);
      _isTyping = true;
      _messageController.clear();
    });
    _scrollToBottom();

    // Ensure Firestore session exists and save the user message
    await _ensureSessionExists(text);
    await _saveMessage(userMsg);

    try {
      final reply = await _gemini.sendMessage(text);
      final botMsg = Message(text: reply, isUser: false);
      if (mounted) {
        setState(() {
          _messages.add(botMsg);
          _isTyping = false;
        });
        await _saveMessage(botMsg);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(Message(
              text: 'Sorry, something went wrong. Please try again.',
              isUser: false));
          _isTyping = false;
        });
      }
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contextLabel = widget.medicine != null
        ? 'Chatting about: ${widget.medicine!.name}'
        : null;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      drawer: _buildDrawer(),
      appBar: AppBar(
        backgroundColor: AppColors.royalBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('MediSafe',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            tooltip: 'Chat History',
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Recent history strip ──
          _buildRecentHistoryHeader(),

          // ── Medicine context label ──
          if (contextLabel != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.royalBlue.withAlpha(20),
              child: Text(contextLabel,
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.royalBlue,
                      fontWeight: FontWeight.w600)),
            ),

          // ── Chat messages ──
          Expanded(
            child: Stack(
              children: [
                ListView.builder(
                  controller: _scrollController,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  itemCount: _messages.length +
                      (_messages.isEmpty ? 1 : 0) +
                      (_isTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (_messages.isEmpty && index == 0) {
                      return _buildWelcomeBubble();
                    }
                    if (_isTyping && index == _messages.length) {
                      return _buildTypingIndicator();
                    }
                    final msg = _messages[index];
                    return _buildChatBubble(msg.text, msg.isUser);
                  },
                ),
              ],
            ),
          ),

          // ── Input Row ──
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Ask MediSafe...',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 15),
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
                    onSubmitted: (_) => _handleSend(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _handleSend,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: AppColors.royalBlue,
                      shape: BoxShape.circle,
                    ),
                    child: _isTyping
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send, color: Colors.white),
                  ),
                ),
              ],
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
            maxWidth: MediaQuery.of(context).size.width * 0.78),
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

  Widget _buildTypingIndicator() => Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 5),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: AppColors.royalBlue,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            _Dot(delay: 0),
            SizedBox(width: 4),
            _Dot(delay: 150),
            SizedBox(width: 4),
            _Dot(delay: 300),
          ]),
        ),
      );

  // ── Burger-menu Drawer: full chat history ──
  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // Full-bleed blue header — no DrawerHeader gutters
          Container(
            width: double.infinity,
            color: AppColors.royalBlue,
            padding: const EdgeInsets.fromLTRB(20, 52, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Icon(Icons.chat_bubble_outline, color: Colors.white, size: 32),
                SizedBox(height: 8),
                Text('Chat History',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          if (_uid.isNotEmpty)
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(_uid)
                    .collection('chat_sessions')
                    .orderBy('lastUpdated', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                        child: Text('No history yet',
                            style: TextStyle(color: Colors.grey)));
                  }
                  final docs = snapshot.data!.docs;
                  return ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: docs.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: Color(0xFFDDE4F0)),
                    itemBuilder: (context, i) {
                      final data =
                          docs[i].data() as Map<String, dynamic>;
                      final title =
                          (data['title'] ?? 'Chat').toString();
                      final medicine =
                          (data['medicineName'] ?? '').toString();
                      return ListTile(
                        leading: const Icon(Icons.chat_bubble_outline,
                            color: AppColors.royalBlue, size: 20),
                        title: Text(title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14)),
                        subtitle: medicine.isNotEmpty
                            ? Text('💊 $medicine',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey))
                            : null,
                        onTap: () {
                          Navigator.pop(context); // close drawer
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ChatbotPage(sessionId: docs[i].id),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          const Divider(height: 1),
          ListTile(
            leading:
                const Icon(Icons.add, color: AppColors.royalBlue),
            title: const Text('New Chat',
                style: TextStyle(
                    color: AppColors.royalBlue,
                    fontWeight: FontWeight.w600)),
            onTap: () {
              Navigator.pop(context); // close drawer
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (_) => const ChatbotPage()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecentHistoryHeader() {
    if (_uid.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Recent Chat History',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(_uid)
                .collection('chat_sessions')
                .orderBy('lastUpdated', descending: true)
                .limit(1)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Container(
                  width: double.infinity,
                  height: 60,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.royalBlue),
                  ),
                  child: const Center(
                      child: Text('No history yet',
                          style: TextStyle(color: Colors.grey))),
                );
              }

              final doc = snapshot.data!.docs.first;
              final data = doc.data() as Map<String, dynamic>;
              final title = (data['title'] ?? 'Chat').toString();
              // Format lastUpdated timestamp
              String dateStr = '';
              final ts = data['lastUpdated'];
              if (ts is Timestamp) {
                final dt = ts.toDate().toLocal();
                dateStr =
                    '${dt.day}/${dt.month}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
              }

              return GestureDetector(
                onTap: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatbotPage(sessionId: doc.id),
                  ),
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.royalBlue),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.royalBlue,
                        ),
                      ),
                      if (dateStr.isNotEmpty) ...
                        [
                          const SizedBox(height: 3),
                          Text(
                            dateStr,
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey),
                          ),
                        ],
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildWelcomeBubble() => Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          padding: const EdgeInsets.all(15),
          decoration: const BoxDecoration(
            color: AppColors.royalBlue,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          child: Text(
            widget.medicine != null
                ? 'Hi! I\'m MediSafe 💊\nI\'m ready to answer your questions about ${widget.medicine!.name}.'
                : 'Hi, I am MediSafe.\nYour Medicine Companion.',
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
      );
}

// ── Animated typing dot ──
class _Dot extends StatefulWidget {
  final int delay;
  const _Dot({required this.delay});
  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0, end: -6).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, _anim.value),
        child: Container(
          width: 8, height: 8,
          decoration: const BoxDecoration(
              color: Colors.white, shape: BoxShape.circle),
        ),
      ),
    );
  }
}