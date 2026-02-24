import 'dart:io';
import 'dart:convert'; 
import 'package:flutter/foundation.dart' show kIsWeb; 
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:medisafe/screens/chatbot_page.dart';
import 'package:medisafe/screens/login_page.dart';
import 'package:medisafe/screens/near_me.dart';
import 'package:medisafe/screens/notification_page.dart';
import 'package:medisafe/screens/schedule_page.dart'; 
import '../colors/color.dart';
import 'package:medisafe/screens/landing_page.dart';
import '../widgets/card.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _remindersEnabled = true;
  XFile? _profileImage;
  final ImagePicker _picker = ImagePicker();

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  Future<void> _pickImage(StateSetter setDialogState) async {
    final XFile? selected = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 400,    // Resize to max 400px width
      maxHeight: 400,   // Resize to max 400px height
      imageQuality: 70, // Compress quality to 70%
    );
    
    if (selected != null) {
      setDialogState(() {
        _profileImage = selected;
      });
    }
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
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(_uid).snapshots(),
        builder: (context, snapshot) {
          String username = "New User";
          String age = "Not Set";
          String profilePicBase64 = "";

          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            username = data['username'] ?? username;
            age = data['age']?.toString() ?? age;
            profilePicBase64 = data['profile_pic_base64'] ?? "";
          }

          ImageProvider? displayImage;
          if (_profileImage != null) {
            displayImage = kIsWeb ? NetworkImage(_profileImage!.path) : FileImage(File(_profileImage!.path)) as ImageProvider;
          } else if (profilePicBase64.isNotEmpty) {
            try {
              displayImage = MemoryImage(base64Decode(profilePicBase64));
            } catch (e) {
              displayImage = null; 
            }
          }

          return Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 45, 
                    backgroundColor: Colors.white, 
                    backgroundImage: displayImage,
                    child: displayImage == null ? const Icon(Icons.person, size: 50, color: AppColors.royalBlue) : null,
                  ),
                  Positioned(
                    bottom: 0, right: 0,
                    child: GestureDetector(
                      onTap: () => _showEditProfileDialog(username, age, profilePicBase64),
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
                Text("Username: $username", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                Text("Age: $age", style: const TextStyle(fontSize: 16)),
              ]),
            ],
          );
        }
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
          _menuItem("Reminders", trailing: Switch(value: _remindersEnabled, onChanged: (v) => setState(() => _remindersEnabled = v), activeColor: AppColors.royalBlue)),
          const Divider(height: 1, color: AppColors.royalBlue),
          _menuItem("About Us", onTap: () => _showAboutUsDialog()),
          const Divider(height: 1, color: AppColors.royalBlue),
          _menuItem("Log Out", trailing: IconButton(icon: const Icon(Icons.logout, color: Colors.black), onPressed: () async {
            await FirebaseAuth.instance.signOut();
            if(mounted) {
              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginPage()), (route) => false);
            }
          })),
          const Divider(height: 1, color: AppColors.royalBlue),
          _menuItem("Delete Account", onTap: _showDeleteAccountDialog),
        ],
      ),
    );
  }

  void _showEditProfileDialog(String currentUsername, String currentAge, String currentBase64) {
    TextEditingController userCtrl = TextEditingController(text: currentUsername);
    TextEditingController ageCtrl = TextEditingController(text: currentAge);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder( 
        builder: (context, setDialogState) {
          
          ImageProvider? previewImage;
          if (_profileImage != null) {
            previewImage = kIsWeb ? NetworkImage(_profileImage!.path) : FileImage(File(_profileImage!.path)) as ImageProvider;
          } else if (currentBase64.isNotEmpty) {
            try { previewImage = MemoryImage(base64Decode(currentBase64)); } catch (_) {}
          }

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
                    backgroundImage: previewImage,
                    child: previewImage == null ? const Icon(Icons.person, size: 40, color: Colors.grey) : null,
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
                      if (_uid.isNotEmpty) {
                        Map<String, dynamic> updateData = {
                          'username': userCtrl.text.trim(),
                          'age': ageCtrl.text.trim(),
                        };

                        if (_profileImage != null) {
                          final bytes = await _profileImage!.readAsBytes();
                          updateData['profile_pic_base64'] = base64Encode(bytes);
                        }

                        await FirebaseFirestore.instance.collection('users').doc(_uid).set(updateData, SetOptions(merge: true)); 
                        
                        setState(() { _profileImage = null; });
                      }
                      if(mounted) Navigator.pop(context);
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
        title: const Text("Delete Account?", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: const Text("This action is permanent and will completely wipe all your medical data, schedules, and allergies. This cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user == null) return;
              
              final uid = user.uid;
              final firestore = FirebaseFirestore.instance;

              Navigator.pop(context);

              try {
                Future<void> deleteSubcollection(String collectionName) async {
                  final snapshot = await firestore.collection('users').doc(uid).collection(collectionName).get();
                  for (var doc in snapshot.docs) {
                    await doc.reference.delete();
                  }
                }

                await deleteSubcollection('schedules');
                await deleteSubcollection('Allergies');
                await deleteSubcollection('MedicalHistory');
                await deleteSubcollection('scan_history');

                await firestore.collection('users').doc(uid).delete();

                await user.delete();

                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context, 
                    MaterialPageRoute(builder: (context) => const LandingScreen()), 
                    (route) => false
                  );
                }
              } on FirebaseAuthException catch (e) {
                if (e.code == 'requires-recent-login') {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Security check: Please log out and log back in before deleting your account."),
                        backgroundColor: Colors.red,
                        duration: Duration(seconds: 4),
                      ),
                    );
                  }
                } else {
                  print("Failed to delete user: ${e.message}");
                }
              }
            },
            child: const Text("Delete Everything", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
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

  void _showAllergiesDialog() { 
    TextEditingController addCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Manage Allergies", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.close, color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 15),

              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                width: double.infinity,
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').doc(_uid).collection('Allergies').orderBy('createdAt', descending: true).snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Text("No allergies found.", style: TextStyle(color: Colors.grey));
                    }

                    return SingleChildScrollView(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 0,
                        children: snapshot.data!.docs.map((doc) {
                          return RemovableTag(
                            label: doc['allergyName'] ?? 'Unnamed',
                            color: AppColors.denimBlue18,
                            onRemove: () async {
                              await doc.reference.delete(); 
                            },
                          );
                        }).toList(),
                      ),
                    );
                  }
                ),
              ),
              
              const Divider(height: 30),

              TextField(
                controller: addCtrl,
                cursorColor: AppColors.royalBlue,
                decoration: InputDecoration(
                  hintText: "Enter new allergy",
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.royalBlue), 
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 15),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.royalBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () async {
                    if (addCtrl.text.isNotEmpty && _uid.isNotEmpty) {
                      await FirebaseFirestore.instance.collection('users').doc(_uid).collection('Allergies').add({
                        'allergyName': addCtrl.text.trim(),
                        'createdAt': FieldValue.serverTimestamp(),
                      });
                      addCtrl.clear();
                    }
                  },
                  child: const Text("Add Allergy", style: TextStyle(fontSize: 16)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _showMedicalHistoryDialog() { 
    TextEditingController diseaseCtrl = TextEditingController();
    String selectedDateStr = "Date";
    DateTime? pickedDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Medical History", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.close, color: Colors.grey)),
                  ]
                ),
                const SizedBox(height: 15),
                
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('users').doc(_uid).collection('MedicalHistory').orderBy('createdAt', descending: true).snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Text("No history found.", style: TextStyle(color: Colors.grey));
                      }

                      return ListView(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        children: snapshot.data!.docs.map((doc) {
                          String displayDate = "";
                          final data = doc.data() as Map<String, dynamic>;
                          
                          if (data.containsKey('date')) {
                            if (doc['date'] is Timestamp) {
                              DateTime dt = (doc['date'] as Timestamp).toDate();
                              displayDate = "${dt.day}/${dt.month}/${dt.year}";
                            } else {
                              displayDate = doc['date'].toString();
                            }
                          }

                          return RemovableTag(
                            label: doc['diseaseName'] ?? 'Unknown',
                            subLabel: displayDate.isNotEmpty ? displayDate : null,
                            color: AppColors.babyBlue21, 
                            onRemove: () async {
                              await doc.reference.delete();
                            },
                          );
                        }).toList(),
                      );
                    }
                  ),
                ),

                const Divider(height: 30),

                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: diseaseCtrl,
                        cursorColor: AppColors.royalBlue,
                        decoration: InputDecoration(
                          hintText: "Enter disease",
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.royalBlue), 
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8), 
                    
                    Expanded(
                      flex: 2,
                      child: InkWell(
                        onTap: () async {
                          DateTime? picked = await showDatePicker(
                            context: context, 
                            initialDate: DateTime.now(), 
                            firstDate: DateTime(1900), 
                            lastDate: DateTime.now(),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: const ColorScheme.light(
                                    primary: AppColors.royalBlue, 
                                    onPrimary: Colors.white,
                                    surface: Colors.white,
                                    onSurface: Colors.black,
                                  ),
                                ),
                                child: child!,
                              );
                            }
                          );
                          if (picked != null) {
                            setDialogState(() {
                              pickedDate = picked;
                              selectedDateStr = "${picked.day}/${picked.month}/${picked.year}";
                            });
                          }
                        },
                        child: Container(
                          height: 48, 
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12)
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  selectedDateStr, 
                                  style: TextStyle(
                                    color: pickedDate == null ? Colors.grey : Colors.black,
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(Icons.calendar_today, size: 16, color: AppColors.royalBlue), 
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 15),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.royalBlue, 
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () async {
                      if (diseaseCtrl.text.isNotEmpty && _uid.isNotEmpty) {
                        Timestamp? ts = pickedDate != null ? Timestamp.fromDate(pickedDate!) : null;
                        
                        await FirebaseFirestore.instance.collection('users').doc(_uid).collection('MedicalHistory').add({
                          'diseaseName': diseaseCtrl.text.trim(),
                          'date': ts ?? Timestamp.now(), 
                          'createdAt': FieldValue.serverTimestamp(),
                        });
                        
                        diseaseCtrl.clear();
                        setDialogState(() {
                          selectedDateStr = "Date"; 
                          pickedDate = null;
                        });
                      }
                    },
                    child: const Text("Add History", style: TextStyle(fontSize: 16)),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFAQDialog() { 
    final List<Map<String, String>> faqs = [
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
        title: const Text("FAQ", style: TextStyle(color: AppColors.royalBlue, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: faqs.length,
            itemBuilder: (context, i) => ExpansionTile(title: Text(faqs[i]['q']!, style: const TextStyle(fontWeight: FontWeight.w600)), children: [Padding(padding: const EdgeInsets.all(8.0), child: Text(faqs[i]['a']!))]),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close"))],
      ),
    );
  }
}