import 'package:flutter/material.dart';
import 'package:medisafe/screens/home_page.dart';
import '../colors/color.dart';

class OptionalInfoPage extends StatefulWidget {
  const OptionalInfoPage({super.key});

  @override
  State<OptionalInfoPage> createState() => _OptionalInfoPageState();
}

class _OptionalInfoPageState extends State<OptionalInfoPage> {
  final List<String> _allergies = [];
  final List<String> _medicalHistory = [];
  
  bool _hasNoAllergies = false;
  bool _hasNoHistory = false;

  final TextEditingController _allergyController = TextEditingController();
  final TextEditingController _historyController = TextEditingController();

  void _navigateToHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const HomePage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.royalBlue,
        elevation: 0,
        title: const Text("MediSafe", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        automaticallyImplyLeading: false, 
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 20),
        child: Column(
          children: [
            const Text(
              "Welcome to MediSafe!",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 15),

            _buildChatbotInfoBox(),
            const SizedBox(height: 25),

            _buildSectionCard(
              title: "Any Allergies?",
              child: Column(
                children: [
                  // Only show input and list if "No Allergies" is NOT active
                  if (!_hasNoAllergies) ...[
                    _buildAddInputField(_allergyController, "e.g. Peanuts", () {
                      if (_allergyController.text.isNotEmpty) {
                        setState(() { _allergies.add(_allergyController.text); });
                        _allergyController.clear();
                      }
                    }),
                    ..._allergies.map((a) => _buildRemovableItem(a, () => setState(() => _allergies.remove(a)))),
                    const SizedBox(height: 10),
                  ],
                  
                  // Updated Toggle Button with specific initial color
                  _buildEmptyStatusLabel(
                    "No Allergies", 
                    _hasNoAllergies, 
                    () => setState(() {
                      _hasNoAllergies = !_hasNoAllergies;
                      if (_hasNoAllergies) _allergies.clear(); 
                    })
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            _buildSectionCard(
              title: "Medical History",
              child: Column(
                children: [
                  if (!_hasNoHistory) ...[
                    _buildAddInputField(_historyController, "e.g. Hypertension", () {
                      if (_historyController.text.isNotEmpty) {
                        setState(() { _medicalHistory.add(_historyController.text); });
                        _historyController.clear();
                      }
                    }),
                    ..._medicalHistory.map((h) => _buildRemovableItem(h, () => setState(() => _medicalHistory.remove(h)))),
                    const SizedBox(height: 10),
                  ],

                  _buildEmptyStatusLabel(
                    "No Medical History", 
                    _hasNoHistory, 
                    () => setState(() {
                      _hasNoHistory = !_hasNoHistory;
                      if (_hasNoHistory) _medicalHistory.clear(); 
                    })
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            _buildPrimaryButton("Save and Continue", AppColors.royalBlue, Colors.white, _navigateToHome),
            const SizedBox(height: 15),
            _buildPrimaryButton("Skip for now", Colors.white, AppColors.royalBlue, _navigateToHome, isBordered: true),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStatusLabel(String text, bool isActive, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? AppColors.royalBlue : const Color(0xFF6A9BDB), 
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppColors.royalBlue, width: 1),
          boxShadow: isActive ? [
            BoxShadow(
              color: AppColors.royalBlue.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ] : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isActive) ...[
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 10),
            ],
            Text(
              text,
              style: const TextStyle(
                color: Colors.white, 
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddInputField(TextEditingController ctrl, String hint, VoidCallback onAdd) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFD1E3F8),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.royalBlue),
      ),
      child: TextField(
        controller: ctrl,
        style: const TextStyle(color: Colors.black), 
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.withOpacity(0.6)), 
          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          border: InputBorder.none,
          suffixIcon: IconButton(icon: const Icon(Icons.add, color: Colors.black), onPressed: onAdd),
        ),
      ),
    );
  }

  Widget _buildRemovableItem(String text, VoidCallback onRemove) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFD1E3F8),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.royalBlue),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(text, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500)),
          GestureDetector(onTap: onRemove, child: const Icon(Icons.remove, color: Colors.black)),
        ],
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
          child: const Text(
            "You may choose to enter your medication details now or complete them later.",
            style: TextStyle(fontSize: 13, height: 1.3),
          ),
        ),
        Container(
          height: 80, width: 80,
          decoration: BoxDecoration(
            color: Colors.white, shape: BoxShape.circle,
            border: Border.all(color: AppColors.royalBlue),
            image: const DecorationImage(image: AssetImage('assets/images/chatbot_logo.png'), fit: BoxFit.contain),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.royalBlue, width: 1)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w400)),
          const Divider(thickness: 1, color: AppColors.royalBlue),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _buildPrimaryButton(String label, Color bg, Color text, VoidCallback action, {bool isBordered = false}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: action,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg, elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
            side: isBordered ? const BorderSide(color: AppColors.royalBlue, width: 1.5) : BorderSide.none,
          ),
        ),
        child: Text(label, style: TextStyle(color: text, fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }
}