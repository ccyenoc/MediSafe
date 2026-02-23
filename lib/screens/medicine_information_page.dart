import 'package:flutter/material.dart';
import '../colors/gradient.dart';
import '../models/medicine_model.dart';
import '../services/gemini_service.dart';
import '../widgets/bottom_nav.dart';
import 'chatbot_page.dart';

class MedicineInfoPage extends StatelessWidget {
  final MedicineModel medicine;
  const MedicineInfoPage({super.key, required this.medicine});

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
            const SizedBox(height: 16),
            _addScheduleButton(context),
            const SizedBox(height: 16),
            _chatButton(context),
            const SizedBox(height: 16),
            if (medicine.personalizedWarning.isNotEmpty) _warningBanner(),
            if (medicine.personalizedWarning.isNotEmpty) const SizedBox(height: 8),
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

  // ── Personalized warning banner ─────────────────────────────
  Widget _warningBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border.all(color: Colors.red),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              medicine.personalizedWarning,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // ── Add to Schedule button ───────────────────────────────────
  Widget _addScheduleButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E3F8F),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          onPressed: () => _showAddScheduleDialog(context),
          icon: const Icon(Icons.add),
          label: const Text("Add To Schedule"),
        ),
      ),
    );
  }

  // ── Chat about this medicine button ─────────────────────────
  Widget _chatButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF1E3F8F),
            side: const BorderSide(color: Color(0xFF1E3F8F)),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatbotPage(
                  medicine: medicine,
                  geminiService: GeminiService()..startChatSession(medicine: medicine),
                ),
              ),
            );
          },
          icon: const Icon(Icons.chat_bubble_outline),
          label: const Text("Chat About This Medicine"),
        ),
      ),
    );
  }

  void _showAddScheduleDialog(BuildContext context) {
    final TextEditingController medicineController =
        TextEditingController(text: medicine.name);
    DateTime selectedDate = DateTime.now();
    int hour = 8;
    int minute = 0;
    String period = "AM";

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Add Schedule",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),
                      const Text("Select Date"),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime.now().subtract(const Duration(days: 365)),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setStateDialog(() => selectedDate = picked);
                          }
                        },
                        child: Container(
                          height: 45,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          alignment: Alignment.centerLeft,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFF1E3F8F)),
                          ),
                          child: Text(
                              "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}"),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text("Time"),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _timeBox(
                            value: hour.toString().padLeft(2, '0'),
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay(hour: hour, minute: minute),
                              );
                              if (picked != null) {
                                setStateDialog(() {
                                  hour = picked.hourOfPeriod == 0 ? 12 : picked.hourOfPeriod;
                                  minute = picked.minute;
                                  period = picked.period == DayPeriod.am ? "AM" : "PM";
                                });
                              }
                            },
                          ),
                          const Text(":"),
                          _timeBox(
                            value: minute.toString().padLeft(2, '0'),
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay(hour: hour, minute: minute),
                              );
                              if (picked != null) {
                                setStateDialog(() {
                                  hour = picked.hourOfPeriod == 0 ? 12 : picked.hourOfPeriod;
                                  minute = picked.minute;
                                  period = picked.period == DayPeriod.am ? "AM" : "PM";
                                });
                              }
                            },
                          ),
                          _timeBox(
                            value: period,
                            onTap: () => setStateDialog(
                                () => period = period == "AM" ? "PM" : "AM"),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text("Medicine"),
                      const SizedBox(height: 8),
                      Container(
                        height: 45,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        alignment: Alignment.centerLeft,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF1E3F8F)),
                        ),
                        child: TextField(
                          controller: medicineController,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isCollapsed: true,
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      Center(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3F8F),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Submit"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _timeBox({required String value, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 45,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF1E3F8F)),
        ),
        child: Text(value, style: const TextStyle(fontSize: 16)),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────
  Widget _header(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 220,
          decoration: const BoxDecoration(
            gradient: AppGradients.blueGradient,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
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
            child: CircleAvatar(radius: 56, backgroundColor: Colors.white),
          ),
        ),
      ],
    );
  }

  // ── Title ──────────────────────────────────────────────────
  Widget _titleSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              medicine.name,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            const CircleAvatar(
              radius: 14,
              backgroundColor: Colors.white,
              child: Text("?"),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          medicine.shortDescription,
          style: const TextStyle(fontStyle: FontStyle.italic),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ── Function ───────────────────────────────────────────────
  Widget _functionSection() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 12).copyWith(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Function",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Text(medicine.function, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  // ── Side Effect + Dosage ──────────────────────────────────
  Widget _sideEffectDosage() {
    return Row(
      children: [
        Expanded(
          child: _sectionCard(
            title: "Side Effects",
            height: 90,
            child: Text(medicine.sideEffects.isEmpty
                ? 'None reported'
                : medicine.sideEffects.join(', ')),
          ),
        ),
        Expanded(
          child: _sectionCard(
            title: "Dosage",
            height: 90,
            child: Text(medicine.dosage.isEmpty ? 'N/A' : medicine.dosage),
          ),
        ),
      ],
    );
  }

  // ── Recipients + Contraindications ───────────────────────
  Widget _recipientSection() {
    return Row(
      children: [
        Expanded(
          child: _sectionCard(
            title: "Suitable For",
            height: 120,
            child: Column(
              children: medicine.recipients.isEmpty
                  ? [const Text('No specific restrictions')]
                  : medicine.recipients
                      .map((r) => _pill(r, Colors.blue.shade100))
                      .toList(),
            ),
          ),
        ),
        Expanded(
          child: _sectionCard(
            title: "Not For These People",
            height: 120,
            child: Column(
              children: medicine.contraindications.isEmpty
                  ? [const Text('None listed')]
                  : medicine.contraindications
                      .map((c) => _pill(c, Colors.red.shade300))
                      .toList(),
            ),
          ),
        ),
      ],
    );
  }

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
            child: SingleChildScrollView(child: child),
          ),
        ],
      ),
    );
  }

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
      child: Text(text, style: const TextStyle(fontSize: 12)),
    );
  }
}
