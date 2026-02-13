import 'package:flutter/material.dart';
import '../colors/gradient.dart';
import '../widgets/bottom_nav.dart';

class MedicineInfoPage extends StatelessWidget {
  final Map<String, dynamic> medicineData;

  const MedicineInfoPage({super.key, required this.medicineData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: const MedicalBottomNav(),
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
            if (medicineData['is_dangerous'] == true) _warningSection(),
            const SizedBox(height: 20),
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
              // TODO: Can show medicine image here if available
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
          children: [
            Text(
              medicineData['name'] ?? "Unknown Medicine",
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(width: 8),
            const CircleAvatar(
              radius: 14,
              backgroundColor: Colors.white,
              child: Text("?"),
            )
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            medicineData['advice'] ?? "No advice available",
            style: const TextStyle(fontStyle: FontStyle.italic),
            textAlign: TextAlign.center,
          ),
        )
      ],
    );
  }

  // 📄 Function
  Widget _functionSection() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 12).copyWith(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Function",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            medicineData['description'] ?? "No description available",
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  // ⚠️ Side effect + dosage
  Widget _sideEffectDosage() {
    // Parse lists safely
    final sideEffects = (medicineData['side_effects'] as List?)?.join(", ") ?? "None listed";
    final dosage = medicineData['dosage'] ?? "Consult doctor";

    return Row(
      children: [
        Expanded(
          child: _sectionCard(
            title: "Side Effect",
            height: 90,
            child: Text(sideEffects),
          ),
        ),
        Expanded(
          child: _sectionCard(
            title: "Dosage",
            height: 90,
            child: Text(dosage),
          ),
        ),
      ],
    );
  }

  // 👥 Recipient / Not for
  Widget _recipientSection() {
    final recipients = (medicineData['recipient_population'] as List?) ?? [];
    final notFor = (medicineData['not_for'] as List?) ?? [];

    return Row(
      children: [
        Expanded(
          child: _sectionCard(
            title: "Recipient Population",
            height: 120,
            child: Column(
              children: recipients.map((e) => _pill(e.toString(), Colors.blue.shade100)).toList(),
            ),
          ),
        ),
        Expanded(
          child: _sectionCard(
            title: "Not For These People",
            height: 120,
            child: Column(
              children: notFor.map((e) => _pill(e.toString(), Colors.red.shade300)).toList(),
            ),
          ),
        ),
      ],
    );
  }

  // ❗ Warning Section
  Widget _warningSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border.all(color: Colors.red),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: const [
          Icon(Icons.warning, color: Colors.red),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              "Important: This medicine may be controlled or have serious risks. Please consult a doctor.",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
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
      child: Text(text, textAlign: TextAlign.center),
    );
  }
}
