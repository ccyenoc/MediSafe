import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_page.dart'; 
import '../colors/color.dart'; 

class OptionalInfoPage extends StatefulWidget {
  const OptionalInfoPage({super.key});

  @override
  State<OptionalInfoPage> createState() => _OptionalInfoPageState();
}

class _OptionalInfoPageState extends State<OptionalInfoPage> {
  final List<String> _allergies = [];
  final List<Map<String, dynamic>> _medicalHistory = []; 
  
  bool _hasNoAllergies = false;
  bool _hasNoHistory = false;

  final TextEditingController _allergyController = TextEditingController();
  final TextEditingController _historyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (userDoc.exists) {
          final age = userDoc.data()?['age'];
          final allergies = userDoc.data()?['allergies'] as List<dynamic>?;
          final medicalHistory = userDoc.data()?['medical_history'] as List<dynamic>?;
          
          setState(() {
            // Update age
            // if (age != null && age > 0) {
            //   _ageController.text = age.toString();
            //   _hasNoAge = false;
            // } else {
            //   _hasNoAge = true;
            // }
            
            // Update allergies
            if (allergies != null && allergies.isNotEmpty) {
              _allergies.clear();
              _allergies.addAll(allergies.cast<String>());
              _hasNoAllergies = false;
            } else {
              _hasNoAllergies = true;
            }
            
            // Update medical history
            if (medicalHistory != null && medicalHistory.isNotEmpty) {
              _medicalHistory.clear();
              _medicalHistory.addAll(
                medicalHistory
                    .whereType<Map<String, dynamic>>()
                    .map((item) {
                      final name = item['name'];
                      final date = item['date'];
                      if (name is! String) return null;
                      final parsedDate = date is Timestamp
                          ? date.toDate()
                          : (date is DateTime ? date : null);
                      if (parsedDate == null) return null;
                      return {
                        'name': name,
                        'date': parsedDate,
                      };
                    })
                    .whereType<Map<String, dynamic>>()
                    .toList(),
              );
              _hasNoHistory = false;
            } else {
              _hasNoHistory = true;
            }
          });
        }
      } catch (e) {
        print('Error loading user data: $e');
      }
    }
  }

  @override
  void dispose() {
    _allergyController.dispose();
    _historyController.dispose();
    // _ageController.dispose();
    super.dispose();
  }

  Future<void> _navigateToHome({bool saveData = true}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (saveData) {
      // Show loading indicator while saving
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );

      try {
        final batch = FirebaseFirestore.instance.batch();
        final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

        // Save Allergies if they exist
        if (!_hasNoAllergies) {
          for (var allergy in _allergies) {
            var ref = userRef.collection('Allergies').doc(); 
            batch.set(ref, {
              'allergyName': allergy, 
              'createdAt': FieldValue.serverTimestamp()
            });
          }
        }

        // Save Medical History if it exists
        if (!_hasNoHistory) {
          for (var history in _medicalHistory) {
            var ref = userRef.collection('MedicalHistory').doc();
            batch.set(ref, {
              'diseaseName': history['name'],
              'date': Timestamp.fromDate(history['date']), 
              'createdAt': FieldValue.serverTimestamp(),
            });
          }
        }
        
        // Execute all saves at once
        await batch.commit();
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error saving data: $e")),
          );
        }
        return;
      }
      
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
      }
    }

    if (mounted) {
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.royalBlue,
        title: const Text("MediSafe", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        automaticallyImplyLeading: false, 
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 20),
        child: Column(
          children: [
            const Text("Welcome to MediSafe!", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500)),
            const SizedBox(height: 15),
            _buildChatbotInfoBox(),
            const SizedBox(height: 25),

            // ALLERGIES SECTION
            _buildSectionCard(
              title: "Any Allergies?",
              child: Column(
                children: [
                  if (!_hasNoAllergies) ...[
                    _buildAddInputField(
                      _allergyController, 
                      "e.g. Peanuts", 
                      () {
                        if (_allergyController.text.trim().isEmpty) {
                          _showWarning("Please type an allergy first.");
                          return;
                        }
                        setState(() { 
                          _allergies.add(_allergyController.text.trim()); 
                        });
                        _allergyController.clear();
                      }, 
                      isHistory: false,
                    ),
                    ..._allergies.map((a) => _buildRemovableItem(
                      a, 
                      null, 
                      () => setState(() => _allergies.remove(a)),
                    )),
                  ],
                  const SizedBox(height: 10),
                  _buildEmptyStatusLabel("No Allergies", _hasNoAllergies, () => setState(() {
                    _hasNoAllergies = !_hasNoAllergies;
                    if (_hasNoAllergies) _allergies.clear(); 
                  })),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // MEDICAL HISTORY SECTION
            _buildSectionCard(
              title: "Medical History",
              child: Column(
                children: [
                  if (!_hasNoHistory) ...[
                    _buildAddInputField(
                      _historyController, 
                      "e.g. Hypertension", 
                      () async {
                        if (_historyController.text.trim().isEmpty) {
                          _showWarning("Please type a condition first.");
                          return;
                        }

                        final String name = _historyController.text.trim();
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: ColorScheme.light(
                                  primary: AppColors.royalBlue, // Themed to your app
                                  onPrimary: Colors.white,
                                  onSurface: Colors.black,
                                ),
                                dialogBackgroundColor: Colors.white,
                              ),
                              child: child!,
                            );
                          },
                        );

                        if (picked != null) {
                          setState(() {
                            _medicalHistory.add({
                              "name": name,
                              "date": picked, 
                            });
                            _historyController.clear();
                          });
                        }
                      }, 
                      isHistory: true,
                    ),
                    ..._medicalHistory.map((h) => _buildRemovableItem(
                      h['name']!, 
                      h['date'] as DateTime, 
                      () => setState(() => _medicalHistory.remove(h))
                    )),
                  ],
                  const SizedBox(height: 10),
                  _buildEmptyStatusLabel("No Medical History", _hasNoHistory, () => setState(() {
                    _hasNoHistory = !_hasNoHistory;
                    if (_hasNoHistory) _medicalHistory.clear(); 
                  })),
                ],
              ),
            ),

            const SizedBox(height: 40),
            _buildPrimaryButton("Save and Continue", AppColors.royalBlue, Colors.white, () => _navigateToHome(saveData: true)),
            const SizedBox(height: 15),
            _buildPrimaryButton("Skip for now", Colors.white, AppColors.royalBlue, () => _navigateToHome(saveData: false), isBordered: true),
          ],
        ),
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildRemovableItem(String title, DateTime? date, VoidCallback onRemove) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFD1E3F8),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.royalBlue),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
                if (date != null)
                  Text("${date.day}/${date.month}/${date.year}", style: const TextStyle(color: Colors.black54, fontSize: 11)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent), 
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20), 
        border: Border.all(color: AppColors.royalBlue, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Divider(thickness: 1.2, color: AppColors.royalBlue),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _buildAddInputField(TextEditingController ctrl, String hint, VoidCallback onAdd, {required bool isHistory}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFD1E3F8), 
        borderRadius: BorderRadius.circular(15), 
        border: Border.all(color: AppColors.royalBlue),
      ),
      child: TextField(
        controller: ctrl,
        decoration: InputDecoration(
          hintText: hint,
          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          border: InputBorder.none,
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min, 
            children: [
              if (isHistory)
                IconButton(
                  icon: const Icon(Icons.calendar_today, size: 20, color: Colors.black54),
                  onPressed: onAdd,
                ),
              IconButton(
                icon: Icon(Icons.add_circle, color: AppColors.royalBlue), 
                onPressed: onAdd,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyStatusLabel(String text, bool isActive, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        width: double.infinity, 
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? AppColors.royalBlue : const Color(0xFF6A9BDB), 
          borderRadius: BorderRadius.circular(15),
        ),
        child: Center(
          child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton(String label, Color bg, Color text, VoidCallback action, {bool isBordered = false}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: action,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg, 
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30), 
            side: isBordered ? BorderSide(color: AppColors.royalBlue) : BorderSide.none,
          ),
        ),
        child: Text(label, style: TextStyle(color: text, fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildChatbotInfoBox() {
    return Stack(
      alignment: Alignment.centerLeft, 
      children: [
        Container(
          margin: const EdgeInsets.only(left: 40), 
          padding: const EdgeInsets.fromLTRB(50, 15, 20, 15),
          decoration: BoxDecoration(
            color: const Color(0xFFD1E3F8), 
            borderRadius: BorderRadius.circular(20), 
            border: Border.all(color: AppColors.royalBlue),
          ),
          child: const Text("Providing your medical details helps MediSafe customize your care!", style: TextStyle(fontSize: 13)),
        ),
        const CircleAvatar(
          radius: 35, 
          backgroundColor: Colors.white, 
          backgroundImage: AssetImage('assets/images/chatbot_logo.png'),
        ),
      ],
    );
  }


  void _showWarning(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}