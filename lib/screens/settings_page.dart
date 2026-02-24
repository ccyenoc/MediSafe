import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medisafe/screens/chatbot_page.dart';
import 'package:medisafe/screens/login_page.dart';
import 'package:medisafe/screens/near_me.dart';
import 'package:medisafe/screens/notification_page.dart';
import 'package:medisafe/screens/schedule_page.dart';
import '../colors/color.dart';
import '../services/firestore_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _username = "New User";
  String _age = "";
  List<String> allergies = [];
  List<Map<String, String>> medicalHistory = [];
  bool _remindersEnabled = true;
  XFile? _profileImage;
  String? _profilePicBase64;
  final ImagePicker _picker = ImagePicker();
  final _firestoreService = FirestoreService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final data = await _firestoreService.getUserProfileOnce();
      if (data != null && mounted) {
        setState(() {
          _username = data['username'] ?? 'New User';
          _age = (data['age'] ?? 0).toString();
          _profilePicBase64 = data['profile_pic_base64'];
          allergies = List<String>.from(data['allergies'] ?? []);
          medicalHistory = List<String>.from(data['medical_history'] ?? [])
              .map((e) => {'name': e, 'date': ''})
              .toList();
          _isLoading = false;
        });
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage(StateSetter setDialogState) async {
    final XFile? selected = await _picker.pickImage(source: ImageSource.gallery);
    if (selected != null) {
      setDialogState(() {
        _profileImage = selected;
      });
    }
  }

  ImageProvider? _getAvatarImage() {
    if (_profileImage != null) {
      return FileImage(File(_profileImage!.path));
    } else if (_profilePicBase64 != null && _profilePicBase64!.isNotEmpty) {
      try {
        return MemoryImage(base64Decode(_profilePicBase64!));
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.royalBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Settings", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildProfileCard(),
            const SizedBox(height: 20),
            
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFFD1E3F8),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.royalBlue, width: 1),
              ),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.95,
                children: [
                  _buildGridItem(Icons.vaccines, "Allergies", () => _showAllergiesDialog()),
                  _buildGridItem(Icons.history_edu, "Medical\nHistory", () => _showMedicalHistoryDialog()),
                  _buildGridItem(Icons.calendar_month, "Schedule", () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const SchedulePage()));
                  }),
                  _buildGridItem(Icons.location_on, "Nearby", () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const NearMePage()));
                  }),
                  _buildGridItem(Icons.notifications_active, "Notification", () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationPage()));
                  }),
                  _buildGridItem(Icons.help_outline, "FAQ", () => _showFAQDialog()),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildBottomMenu(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFFD1E3F8), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.royalBlue)),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 45, 
                backgroundColor: Colors.white, 
                backgroundImage: _getAvatarImage(),
                child: _getAvatarImage() == null ? const Icon(Icons.person, size: 50, color: AppColors.royalBlue) : null,
              ),
              Positioned(
                bottom: 0, right: 0,
                child: GestureDetector(
                  onTap: _showEditProfileDialog,
                  child: Container(
                    padding: const EdgeInsets.all(4), 
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), 
                    child: const Icon(Icons.edit, size: 16, color: Colors.black)
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("Username: $_username", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            Text("Age: $_age", style: const TextStyle(fontSize: 16)),
          ]),
        ],
      ),
    );
  }

  Widget _buildBottomMenu() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFD1E3F8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.royalBlue),
      ),
      child: Column(
        children: [
          _menuItem(
            "AI Explanations", 
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Detailed ", style: TextStyle(color: Colors.grey, fontSize: 14)), 
                IconButton(
                  icon: const Icon(Icons.arrow_forward, color: Colors.black),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ChatbotPage())),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.royalBlue),
          _menuItem("Reminders", trailing: Switch(value: _remindersEnabled, onChanged: (v) => setState(() => _remindersEnabled = v), activeColor: AppColors.blue1)),
          const Divider(height: 1, color: AppColors.royalBlue),
          _menuItem("About Us", onTap: () => _showAboutUsDialog()),
          const Divider(height: 1, color: AppColors.royalBlue),
          _menuItem("Log Out", trailing: IconButton(icon: const Icon(Icons.logout, color: Colors.black), onPressed: () async {
            print('[AUTH] Signing out user');
            await FirebaseAuth.instance.signOut();
            print('[AUTH] ✅ User signed out');
            if (mounted) {
              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginPage()), (route) => false);
            }
          })),
          const Divider(height: 1, color: AppColors.royalBlue),
          _menuItem("Delete Account", onTap: _showDeleteAccountDialog),
        ],
      ),
    );
  }

  void _showEditProfileDialog() {
    TextEditingController userCtrl = TextEditingController(text: _username);
    TextEditingController ageCtrl = TextEditingController(text: _age);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder( 
        builder: (context, setDialogState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Edit Profile", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    backgroundImage: _getAvatarImage(),
                    child: _getAvatarImage() == null ? const Icon(Icons.person, size: 40, color: Colors.grey) : null,
                  ),
                  const Text("Change profile picture", style: TextStyle(fontSize: 12)),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => _pickImage(setDialogState), 
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7BAAE0), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    child: const Text("Upload", style: TextStyle(color: Colors.black)),
                  ),
                  const SizedBox(height: 15),
                  _dialogField("Username:", userCtrl),
                  _dialogField("Age:", ageCtrl),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      setState(() { 
                        _username = userCtrl.text; 
                        _age = ageCtrl.text; 
                      });
                      
                      String? base64Str;
                      if (_profileImage != null) {
                        final bytes = await File(_profileImage!.path).readAsBytes();
                        base64Str = base64Encode(bytes);
                        _profilePicBase64 = base64Str;
                      }
                      
                      final parsedAge = int.tryParse(ageCtrl.text) ?? 0;
                      await _firestoreService.updateProfileBasicInfo(_username, parsedAge, base64Str);
                      if (mounted) Navigator.pop(context);
                    },
                    child: const Text("Save"),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAboutUsDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Our Team", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.royalBlue)),
                  GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.close, color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 10),
              const Text("git force push", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black54)),
              const Divider(height: 30, color: Colors.blueGrey),
              _teamMemberCard("Brayden Chong", "Project Manager", Icons.leaderboard),
              _teamMemberCard("Ong Yean", "Backend Developer", Icons.storage),
              _teamMemberCard("Chin Yiu Ern", "Frontend Developer", Icons.web),
              _teamMemberCard("Lim Wan Yee", "Frontend Developer", Icons.phone_android),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Delete Account?"),
        content: const Text("This action is permanent and will wipe all your medical data."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              _deleteAccountPermanently(context);
              setState(() {
                _username = "New User"; _age = ""; allergies.clear(); medicalHistory.clear(); _profileImage = null;
              });
              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginPage()), (route) => false);
            },
            child: const Text("Delete Everything", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccountPermanently(BuildContext dialogContext) async {
    // Close the confirmation dialog first
    Navigator.pop(dialogContext);
    
    // Show loading dialog
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (loadingContext) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text("Deleting account..."),
          ],
        ),
      ),
    );

    try {
      final user = FirebaseAuth.instance.currentUser;
      
      if (user != null) {
        // Step 1: Delete Firestore document
        print('[DELETE] Deleting Firestore user document for uid: ${user.uid}');
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .delete();
        print('[DELETE] ✅ Firestore document deleted');

        // Step 2: Delete Firebase Auth account
        print('[DELETE] Deleting Firebase Auth account for uid: ${user.uid}');
        await user.delete();
        print('[DELETE] ✅ Firebase Auth account deleted');

        // Close loading dialog and navigate to login
        if (mounted) {
          Navigator.pop(context); // Close loading dialog
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
            (route) => false,
          );
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account deleted successfully'),
              duration: Duration(seconds: 2),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        print('[DELETE] ❌ Auth deletion error: ${e.code} - ${e.message}');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting account: ${e.message}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        print('[DELETE] ❌ Firestore deletion error: ${e.code} - ${e.message}');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting data: ${e.message}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        print('[DELETE] ❌ Unexpected error: $e');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unexpected error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Widget _buildGridItem(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(color: const Color(0xFF7BAAE0), borderRadius: BorderRadius.circular(15)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: Colors.black87, size: 30),
          const SizedBox(height: 5),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }

  Widget _teamMemberCard(String name, String role, IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.denimBlue18, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          CircleAvatar(radius: 20, backgroundColor: AppColors.royalBlue, child: Icon(icon, size: 18, color: Colors.white)),
          const SizedBox(width: 15),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            Text(role, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ]),
        ],
      ),
    );
  }

  Widget _menuItem(String title, {Widget? trailing, VoidCallback? onTap}) => ListTile(title: Text(title, style: const TextStyle(fontSize: 16)), trailing: trailing, onTap: onTap);

  Widget _dialogField(String label, TextEditingController ctrl) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 14)),
      Container(
        margin: const EdgeInsets.symmetric(vertical: 5), padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(color: const Color(0xFFD1E3F8), borderRadius: BorderRadius.circular(15), border: Border.all(color: AppColors.royalBlue)),
        child: TextField(controller: ctrl, decoration: const InputDecoration(border: InputBorder.none)),
      ),
    ],
  );

  Widget _listInput(String hint, IconData icon, VoidCallback onTap, {TextEditingController? controller}) => Container(
    margin: const EdgeInsets.symmetric(vertical: 5), padding: const EdgeInsets.symmetric(horizontal: 15),
    decoration: BoxDecoration(color: const Color(0xFFD1E3F8), borderRadius: BorderRadius.circular(15), border: Border.all(color: AppColors.royalBlue)),
    child: Row(
      children: [
        Expanded(child: TextField(controller: controller, readOnly: controller == null, decoration: InputDecoration(hintText: hint, border: InputBorder.none))),
        IconButton(icon: Icon(icon), onPressed: onTap),
      ],
    ),
  );

  void _showAllergiesDialog() { TextEditingController addCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(children: [Text("Allergies ", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), Icon(Icons.edit, size: 18)]),
                    GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.cancel_outlined)),
                  ],
                ),
                const SizedBox(height: 20),
                ...allergies.map((a) => _listInput(a, Icons.remove, () async {
                  await _firestoreService.removeAllergy(a);
                  setState(() => allergies.remove(a));
                  setDialogState(() {});
                })),
                _listInput("Add", Icons.add, () async {
                  if (addCtrl.text.isNotEmpty) {
                    await _firestoreService.addAllergy(addCtrl.text);
                    setState(() => allergies.add(addCtrl.text));
                    addCtrl.clear();
                    setDialogState(() {});
                  }
                }, controller: addCtrl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showMedicalHistoryDialog() { TextEditingController diseaseCtrl = TextEditingController();
    String selectedDate = "Choose Date";

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Medical History", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                ...medicalHistory.map((h) => ListTile(title: Text(h['name']!), subtitle: Text(h['date']!))),
                TextField(controller: diseaseCtrl, decoration: const InputDecoration(hintText: "Enter disease")),
                TextButton(
                  onPressed: () async {
                    DateTime? picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
                    if (picked != null) setDialogState(() => selectedDate = "${picked.day}/${picked.month}/${picked.year}");
                  },
                  child: Text(selectedDate),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (diseaseCtrl.text.isNotEmpty) {
                      await _firestoreService.addMedicalHistory(diseaseCtrl.text);
                      setState(() => medicalHistory.add({"name": diseaseCtrl.text, "date": selectedDate}));
                      if (mounted) Navigator.pop(context);
                    }
                  },
                  child: const Text("Add History"),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFAQDialog() { final List<Map<String, String>> faqs = [
      {"q": "What is MediSafe?", "a": "A smart companion for managing your medications and health records."},
      {"q": "How do I add a reminder?", "a": "Navigate to the Schedule page and record your medication details."},
      {"q": "Is my medical data secure?", "a": "Yes, all personal data is encrypted and stored locally on your device."},
      {"q": "Can I track family members?", "a": "This feature is coming soon in our next update!"},
      {"q": "How does 'Nearby' work?", "a": "It uses GPS to find hospitals, clinics and pharmacies around your current location."},
      {"q": "How does the Scanner function?", "a": "You can scan or upload your prescription using the built-in scanner and our OCR technology automatically recognizes the prescription and extracts medicine details such as name, function, and dosage."},
      {"q": "What does the AI chatbot do?", "a": "It provides information about medicines and general health tips."},
      {"q": "How do I change my profile?", "a": "Press the pen icon on the settings page profile card."},
      {"q": "Does the app work offline?", "a": "Yes, your reminders and history are accessible without internet."},
      {"q": "How do I delete my data?", "a": "Use the 'Delete Account' button at the bottom of settings."},
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("FAQ"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: faqs.length,
            itemBuilder: (context, i) => ExpansionTile(title: Text(faqs[i]['q']!), children: [Padding(padding: const EdgeInsets.all(8.0), child: Text(faqs[i]['a']!))]),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close"))],
      ),
    );
  }
}