import 'package:flutter/material.dart';
import '../colors/gradient.dart';

class MedicineInfoPage extends StatelessWidget {
  const MedicineInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _header(context),
            const SizedBox(height: 70),
            _titleSection(),
            const SizedBox(height: 24),
            _functionSection(),
            _sideEffectDosage(),
            const SizedBox(height: 16),
            _recipientSection(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // 🔵 Header
  Widget _header(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 220,
          decoration: const BoxDecoration(
            gradient: AppGradients.blueGradient,
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(40),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const CircleAvatar(backgroundColor: Colors.white),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: -60,
          left: 0,
          right: 0,
          child: CircleAvatar(
            radius: 60,
            backgroundColor: Colors.white,
            child: CircleAvatar(
              radius: 56,
              backgroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  // 🧠 Title
  Widget _titleSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text(
              "Panadol",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            SizedBox(width: 8),
            CircleAvatar(
              radius: 14,
              backgroundColor: Colors.white,
              child: Text("?"),
            )
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          "short description",
          style: TextStyle(fontStyle: FontStyle.italic),
        )
      ],
    );
  }

// 📄 Function (no card)
// 📄 Function (no card, wraps content)
Widget _functionSection() {
  return Container(
    width: double.infinity, // ensures it takes full width
    margin: const EdgeInsets.symmetric(horizontal: 12).copyWith(bottom: 16), // horizontal + bottom spacing
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, // left-align text
      children: const [
        Text(
          "Function",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        SizedBox(height: 8),
        Text(
          "Pain relief and fever reduction",
          style: TextStyle(fontSize: 14),
        ),
      ],
    ),
  );
}



  // ⚠️ Side effect + dosage
  Widget _sideEffectDosage() {
    return Row(
      children: [
        Expanded(
          child: _sectionCard(
            title: "Side Effect",
            height: 90,
            child: const Text("Nausea, rash"),
          ),
        ),
        Expanded(
          child: _sectionCard(
            title: "Dosage",
            height: 90,
            child: const Text("500mg – 1000mg"),
          ),
        ),
      ],
    );
  }

  // 👥 Recipient / Not for
  Widget _recipientSection() {
    return Row(
      children: [
        Expanded(
          child: _sectionCard(
            title: "Recipient Population",
            height: 120,
            child: Column(
              children: [
                _pill("Adults", Colors.blue.shade100),
                _pill("Children", Colors.blue.shade100),
              ],
            ),
          ),
        ),
        Expanded(
          child: _sectionCard(
            title: "Not For These People",
            height: 120,
            child: Column(
              children: [
                _pill("Liver disease", Colors.red.shade300),
                _pill("Alcohol abuse", Colors.red.shade300),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 🧱 Reusable card
  Widget _sectionCard({
  required String title,
  required double height,
  required Widget child,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          height: height,
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black),
          ),
          // ✅ Make content scrollable inside the card
          child: SingleChildScrollView(
            child: child,
          ),
        ),
      ],
    ),
  );
}

  // 💊 Pill widget
  Widget _pill(String text, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(vertical: 10),
      width: double.infinity,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: Alignment.center,
      child: Text(text),
    );
  }

}
