import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:medisafe/widgets/floating_chatbot.dart';
import '../colors/color.dart';
import '../widgets/card.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/chatbot_button.dart';
import '../widgets/header_actions.dart';
import 'chatbot_page.dart';
import 'dart:async';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final String _uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  
  final List<Message> _sharedMessages = []; 
  final TextEditingController _sharedController = TextEditingController();
  final TextEditingController _inputController = TextEditingController();

  Timer? _minuteTimer;

  @override
  void initState() {
    super.initState();
    _minuteTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) setState(() {}); 
    });
  }

  @override
  void dispose() {
    _minuteTimer?.cancel(); // Always cancel timers when leaving the page to save memory
    super.dispose();
  }

  Future<void> _addData(String category, String value, {dynamic date}) async {
    if (_uid.isEmpty || value.isEmpty) return;
    
    final userRef = FirebaseFirestore.instance.collection('users').doc(_uid);

    if (category == "Allergy") {
      await userRef.collection('Allergies').add({
        'allergyName': value, 
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else if (category == "History") {
      await userRef.collection('MedicalHistory').add({
        'diseaseName': value, 
        'date': (date == null || date == "") ? Timestamp.now() : date, 
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> _deleteData(String collectionPath, String docId) async {
    if (_uid.isEmpty) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .collection(collectionPath)
        .doc(docId)
        .delete();
  }

  void _openFloatingChat() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => FloatingChatbot(
        messages: _sharedMessages,
        controller: _sharedController,
        onSend: (text) {
          setState(() {
            _sharedMessages.add(Message(text: text, isUser: true));
            _sharedMessages.add(Message(text: "Analyzing your medical query...", isUser: false));
          });
        },
      ),
    );
  }

  void _showAddDialog(String category) async {
    _inputController.clear();
    String selectedDateStr = "Choose Date";
    DateTime? pickedDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder( 
        builder: (context, setDialogState) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: Colors.red,
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: Colors.black,
              ),
            ),
            child: AlertDialog(
              backgroundColor: Colors.white,
              title: Text("Add $category", style: const TextStyle(fontWeight: FontWeight.w600)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _inputController,
                    autofocus: true,
                    cursorColor: Colors.red,
                    decoration: InputDecoration(
                      hintText: category == "History" ? "Enter disease name" : "Enter details",
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.red),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                  if (category == "History") ...[
                    const SizedBox(height: 15),
                    InkWell(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            pickedDate = picked;
                            selectedDateStr = "${picked.day}/${picked.month}/${picked.year}";
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(selectedDateStr, style: TextStyle(color: pickedDate == null ? Colors.grey : Colors.black)),
                            const Icon(Icons.calendar_today, size: 18, color: Colors.red),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _inputController.clear();
                    Navigator.pop(context);
                  },
                  child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_inputController.text.isNotEmpty) {
                      Timestamp? ts = pickedDate != null ? Timestamp.fromDate(pickedDate!) : null;
                      _addData(category, _inputController.text.trim(), date: ts);
                      
                      _inputController.clear();
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Add"),
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header 
            Container(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
              decoration: const BoxDecoration(color: AppColors.royalBlue),
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('users').doc(_uid).snapshots(),
                builder: (context, snapshot) {
                  String username = "New User";
                  String age = "";
                  
                  if (snapshot.hasData && snapshot.data!.exists) {
                    final data = snapshot.data!.data() as Map<String, dynamic>?;
                    if (data != null) {
                      if (data.containsKey('username')) username = data['username'];
                      if (data.containsKey('age')) age = data['age'].toString();
                    }
                  }

                  return Row(
                    children: [
                      const CircleAvatar(
                        radius: 45, 
                        backgroundColor: AppColors.white, 
                        child: Icon(Icons.person, size: 50, color: AppColors.royalBlue)
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(username, style: const TextStyle(color: AppColors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                            Text("Age : $age", style: const TextStyle(color: AppColors.white)),
                          ],
                        ),
                      ),
                      const HeaderActions(), 
                    ],
                  );
                }
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  CustomSectionBox(
                    title: "Upcoming Dose",
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(_uid)
                          .collection('schedules')
                          .where('isActive', isEqualTo: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(child: Text("Empty", style: TextStyle(color: Colors.grey, fontSize: 12)));
                        }

                        final docs = snapshot.data!.docs;
                        DateTime now = DateTime.now();
                        
                        List<Map<String, dynamic>> upcomingDoses = [];

                        for (var doc in docs) {
                          final data = doc.data() as Map<String, dynamic>;
                          
                          if (data.containsKey('time') && data['time'] is Timestamp) {
                            DateTime dt = (data['time'] as Timestamp).toDate();
                            
                            bool isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;
                            
                            //  Must be today AND the time must be in the future
                            if (isToday && dt.isAfter(now)) {
                              upcomingDoses.add({
                                'medName': data['medicineName']?.toString().trim() ?? 'Unnamed Med',
                                'dt': dt,
                              });
                            }
                          }
                        }

                        // If all doses for today are already in the past
                        if (upcomingDoses.isEmpty) {
                          return const Center(
                            child: Text("All doses completed for today! 🎉", 
                            style: TextStyle(color: Colors.grey, fontSize: 12))
                          );
                        }

                        // Sort the list so the earliest upcoming time is at the very top (index 0)
                        upcomingDoses.sort((a, b) => (a['dt'] as DateTime).compareTo(b['dt'] as DateTime));
                        
                        // Get the exact time of the nearest dose
                        DateTime nearestTime = upcomingDoses.first['dt'];
                        
                        // Find ALL medicines that share this exact nearest time (in case there are 2 pills at 8:00 PM)
                        List<String> medsForNearestTime = upcomingDoses
                            .where((dose) => (dose['dt'] as DateTime).isAtSameMomentAs(nearestTime))
                            .map((dose) => dose['medName'] as String)
                            .toSet() // Use .toSet() just in case the same med was accidentally logged twice for the same time
                            .toList();

                        // Format the time to look clean (e.g. "8:00 PM")
                        int hour = nearestTime.hour > 12 ? nearestTime.hour - 12 : (nearestTime.hour == 0 ? 12 : nearestTime.hour);
                        String minute = nearestTime.minute.toString().padLeft(2, '0');
                        String period = nearestTime.hour >= 12 ? "PM" : "AM";
                        String formattedTime = "$hour:$minute $period";

                        return IntrinsicHeight(
                          child: Row(
                            children: [
                              Text(formattedTime, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const VerticalDivider(color: AppColors.royalBlue, width: 30, thickness: 1.5),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  // Automatically capitalize the medicine name
                                  children: medsForNearestTime.map((med) {
                                    String displayMed = med[0].toUpperCase() + med.substring(1);
                                    return Text(displayMed, style: const TextStyle(fontSize: 15));
                                  }).toList(),
                                ),
                              )
                            ],
                          ),
                        );
                      }
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: CustomSectionBox(
                          title: "Allergies",
                          height: 220,
                          onAddPressed: () => _showAddDialog("Allergy"),
                          child: Column(
                            children: [
                              Expanded(
                                child: StreamBuilder<QuerySnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(_uid)
                                      .collection('Allergies')
                                      .orderBy('createdAt', descending: true)
                                      .snapshots(),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                      return const Center(child: CircularProgressIndicator());
                                    }
                                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                                      return const Center(child: Text("Empty", style: TextStyle(color: Colors.grey, fontSize: 10)));
                                    }

                                    final docs = snapshot.data!.docs;
                                    return ListView(
                                      padding: EdgeInsets.zero,
                                      children: docs.map((doc) => RemovableTag(
                                        label: doc['allergyName'] ?? 'Unnamed', 
                                        color: AppColors.denimBlue18,
                                        onRemove: () => _deleteData('Allergies', doc.id),
                                      )).toList(),
                                    );
                                  },
                                ),
                              ),
                              AddTagPlaceholder(onTap: () => _showAddDialog("Allergy")),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      
                      Expanded(
                        child: CustomSectionBox(
                          title: "Medical History",
                          height: 220,
                          onAddPressed: () => _showAddDialog("History"),
                          child: Column(
                            children: [
                              Expanded(
                                child: StreamBuilder<QuerySnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(_uid)
                                      .collection('MedicalHistory')
                                      .orderBy('createdAt', descending: true)
                                      .snapshots(),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                      return const Center(child: CircularProgressIndicator());
                                    }
                                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                                      return const Center(child: Text("Empty", style: TextStyle(color: Colors.grey, fontSize: 10)));
                                    }

                                    final docs = snapshot.data!.docs;
                                    return ListView(
                                      padding: EdgeInsets.zero,
                                      children: docs.map((doc) {
                                        
                                        String displayDate = "";
                                        final dataMap = doc.data() as Map<String, dynamic>;
                                        
                                        if (dataMap.containsKey('date')) {
                                          if (doc['date'] is Timestamp) {
                                            DateTime dt = (doc['date'] as Timestamp).toDate();
                                            displayDate = "${dt.day}/${dt.month}/${dt.year}";
                                          } else {
                                            displayDate = doc['date'].toString();
                                          }
                                        }

                                        return RemovableTag(
                                          label: doc['diseaseName'] ?? 'No Name', 
                                          subLabel: displayDate.isNotEmpty ? displayDate : null,
                                          color: AppColors.babyBlue21,
                                          onRemove: () => _deleteData('MedicalHistory', doc.id),
                                        );
                                      }).toList(),
                                    );
                                  },
                                ),
                              ),
                              AddTagPlaceholder(onTap: () => _showAddDialog("History")),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  CustomSectionBox(
                    title: "Active Medicine",
                    height: 150,
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(_uid)
                          .collection('schedules')
                          .where('isActive', isEqualTo: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(child: Text("Empty", style: TextStyle(color: Colors.grey, fontSize: 12)));
                        }

                        final docs = snapshot.data!.docs;
                        DateTime now = DateTime.now();
                        
                        
                        Map<String, String> uniqueActiveMedicines = {};

                        for (var doc in docs) {
                          final data = doc.data() as Map<String, dynamic>;
                          
                          if (data.containsKey('time') && data['time'] is Timestamp) {
                            DateTime dt = (data['time'] as Timestamp).toDate();
                            
                            bool isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;
                            
                            if (isToday) {
                              final rawMedName = data['medicineName']?.toString().trim() ?? 'Unknown Med';
                              
                              if (rawMedName.isNotEmpty) {
                                final searchKey = rawMedName.toLowerCase();
                                
                                if (!uniqueActiveMedicines.containsKey(searchKey)) {
                                  String displayName = rawMedName[0].toUpperCase() + rawMedName.substring(1);
                                  uniqueActiveMedicines[searchKey] = displayName;
                                }
                              }
                            }
                          }
                        }

                        if (uniqueActiveMedicines.isEmpty) {
                          return const Center(child: Text("Empty", style: TextStyle(color: Colors.grey, fontSize: 12)));
                        }

                        return ListView(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          children: uniqueActiveMedicines.values.map((medName) {
                            return RemovableTag(
                              label: medName,
                              color: const Color(0xFFD1E3F8),
                              onRemove: () {}, 
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: ChatbotButton(onPressed: _openFloatingChat),
      bottomNavigationBar: const MedicalBottomNav(),
    );
  }
}