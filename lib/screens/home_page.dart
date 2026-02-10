import 'package:flutter/material.dart';
import '../colors/color.dart';
import '../widgets/card.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/chatbot_button.dart';
import '../widgets/header_actions.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<Map<String, String>> _doses = []; 
  final List<String> _allergies = [];
  final List<Map<String, String>> _medicalHistory = [];
  
  final TextEditingController _inputController = TextEditingController();

  void _showAddDialog(String category) {
  showDialog(
    context: context,
    builder: (context) => Theme(
      data: Theme.of(context).copyWith(
        colorScheme: const ColorScheme.light(
          primary: Colors.red,       // 👈 button + cursor
          onPrimary: Colors.white,   // 👈 text on red
          surface: Colors.white,
          onSurface: Colors.black,
        ),
      ),
      child: AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          "Add $category",
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        content: TextField(
          controller: _inputController,
          autofocus: true,
          cursorColor: Colors.red,
          decoration: InputDecoration(
            hintText: "Enter $category details",
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (_inputController.text.isNotEmpty) {
                setState(() {
                  if (category == "Allergy") {
                    _allergies.add(_inputController.text);
                  } else if (category == "History") {
                    _medicalHistory.add({
                      "name": _inputController.text,
                      "date": "Added Today"
                    });
                  } else if (category == "Dose") {
                    _doses.add({
                      "time": "8.00 AM",
                      "med": _inputController.text
                    });
                  }
                });
                _inputController.clear();
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text("Add"),
          ),
        ],
      ),
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
            Container(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
              decoration: const BoxDecoration(color: AppColors.royalBlue),
              child: const Row(
                children: [
                  CircleAvatar(
                    radius: 45, 
                    backgroundColor: AppColors.white, 
                    child: Icon(Icons.person, size: 50, color: AppColors.royalBlue)
                  ),
                  SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("New User", style: TextStyle(color: AppColors.white, fontSize: 22, fontWeight: FontWeight.bold)), //
                        Text("Age : ", style: TextStyle(color: AppColors.white)), //
                      ],
                    ),
                  ),
                  HeaderActions(), 
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  CustomSectionBox(
                    title: "Upcoming Dose",
                    showAdd: false, //
                    child: _doses.isEmpty 
                      ? const Center(child: Text("Empty", style: TextStyle(color: Colors.grey, fontSize: 12))) //
                      : IntrinsicHeight(
                          child: Row(
                            children: [
                              Text(_doses.first['time']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                              const VerticalDivider(color: AppColors.royalBlue, width: 30, thickness: 1.5),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: _doses.map((d) => Text(d['med']!)).toList(),
                              )
                            ],
                          ),
                        ),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: CustomSectionBox(
                          title: "Allergies",
                          showAdd: true, //
                          height: 220,
                          onAddPressed: () => _showAddDialog("Allergy"),
                          child: Column(
                            children: [
                              Expanded(
                                child: _allergies.isEmpty 
                                  ? const Center(child: Text("Empty", style: TextStyle(color: Colors.grey, fontSize: 10)))
                                  : ListView(
                                      padding: EdgeInsets.zero,
                                      children: _allergies.map((a) => RemovableTag(
                                        label: a, 
                                        color: AppColors.denimBlue18,
                                        onRemove: () => setState(() => _allergies.remove(a)),
                                      )).toList(),
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
                          showAdd: true, //
                          height: 220,
                          onAddPressed: () => _showAddDialog("History"),
                          child: Column(
                            children: [
                              Expanded(
                                child: _medicalHistory.isEmpty
                                  ? const Center(child: Text("Empty", style: TextStyle(color: Colors.grey, fontSize: 10)))
                                  : ListView(
                                      padding: EdgeInsets.zero,
                                      children: _medicalHistory.map((h) => RemovableTag(
                                        label: h['name']!, 
                                        subLabel: h['date'],
                                        color: AppColors.babyBlue21,
                                        onRemove: () => setState(() => _medicalHistory.remove(h)),
                                      )).toList(),
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

                  const CustomSectionBox(
                    title: "Active Medicine",
                    showAdd: false, 
                    height: 150,
                    child: Center(child: Text("Empty", style: TextStyle(color: Colors.grey, fontSize: 12))), 
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: ChatbotButton(onPressed: () {}),
      bottomNavigationBar: const MedicalBottomNav(),
    );
  }
}