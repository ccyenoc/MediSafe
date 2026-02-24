import 'dart:io';
import 'package:flutter/material.dart';
import '../colors/gradient.dart';
import '../models/medicine_model.dart';
import '../services/gemini_service.dart';
import '../widgets/bottom_nav.dart';
import 'chatbot_page.dart';

class MedicineInfoPage extends StatelessWidget {
  final MedicineModel medicine;
  final String? imagePath;

  const MedicineInfoPage({
    super.key,
    required this.medicine,
    this.imagePath,
  });

  static const _primary = Color(0xFF1E3F8F);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      bottomNavigationBar: const MedicalBottomNav(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _header(context),
            const SizedBox(height: 80), // space for the circle avatar
            // Medicine name
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                medicine.name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (medicine.shortDescription.isNotEmpty) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  medicine.shortDescription,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            const SizedBox(height: 20),
            if (medicine.personalizedWarning.isNotEmpty) ...[
              _warningBanner(),
              const SizedBox(height: 12),
            ],
            // Action buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      onPressed: () => _showAddScheduleDialog(context),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Schedule',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _primary,
                        side: const BorderSide(color: _primary),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatbotPage(
                            medicine: medicine,
                            geminiService: GeminiService()
                              ..startChatSession(medicine: medicine),
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.chat_bubble_outline, size: 18),
                      label: const Text('Ask AI',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Info cards
            _card(
              icon: Icons.medical_services_outlined,
              iconColor: const Color(0xFF00897B),
              title: '💊 What it does',
              body: medicine.function,
            ),
            _card(
              icon: Icons.schedule,
              iconColor: const Color(0xFF6200EA),
              title: '🕐 How to take it',
              body: null,
              dosageLines: medicine.dosage.isEmpty
                  ? ['Follow the instructions on the box or ask your doctor.']
                  : medicine.dosage.split('\n').where((l) => l.trim().isNotEmpty).toList(),
            ),
            if (medicine.sideEffects.isNotEmpty)
              _chipCard(
                icon: Icons.warning_amber_outlined,
                iconColor: const Color(0xFFE65100),
                title: '⚠️ Possible side effects',
                items: medicine.sideEffects,
                chipColor: Colors.orange.shade50,
                chipBorder: Colors.orange.shade300,
              ),
            if (medicine.recipients.isNotEmpty)
              _chipCard(
                icon: Icons.check_circle_outline,
                iconColor: const Color(0xFF2E7D32),
                title: '✅ Who can take it',
                items: medicine.recipients,
                chipColor: Colors.green.shade50,
                chipBorder: Colors.green.shade300,
              ),
            if (medicine.contraindications.isNotEmpty)
              _chipCard(
                icon: Icons.block,
                iconColor: const Color(0xFFC62828),
                title: '🚫 Who should NOT take it',
                items: medicine.contraindications,
                chipColor: Colors.red.shade50,
                chipBorder: Colors.red.shade300,
              ),
            if (medicine.allergies.isNotEmpty)
              _chipCard(
                icon: Icons.coronavirus_outlined,
                iconColor: const Color(0xFFAD1457),
                title: '🧬 Allergy warnings',
                items: medicine.allergies,
                chipColor: Colors.pink.shade50,
                chipBorder: Colors.pink.shade300,
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── Original gradient header with round photo circle ──────────
  Widget _header(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Gradient top bar
        Container(
          height: 220,
          decoration: const BoxDecoration(
            gradient: AppGradients.blueGradient,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Round medicine photo in the centre
        Positioned(
          bottom: -60,
          left: 0,
          right: 0,
          child: Center(
            child: CircleAvatar(
              radius: 62,
              backgroundColor: Colors.white,
              child: CircleAvatar(
                radius: 57,
                backgroundColor: const Color(0xFFEEF2FF),
                backgroundImage: imagePath != null
                    ? FileImage(File(imagePath!))
                    : null,
                child: imagePath == null
                    ? const Icon(Icons.medication,
                        size: 48, color: Color(0xFF1E3F8F))
                    : null,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Warning banner ──────────────────────────────────────────
  Widget _warningBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border.all(color: Colors.red.shade300),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              medicine.personalizedWarning,
              style: const TextStyle(
                  color: Colors.red, fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  // ── Text info card ──────────────────────────────────────────
  Widget _card({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? body,
    List<String>? dosageLines,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: iconColor)),
          const SizedBox(height: 8),
          if (dosageLines != null)
            // Render each dosage line as a clean row
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: dosageLines.map((line) {
                // Split "Amount: 1 sachet" into label + value if colon present
                final colonIdx = line.indexOf(':');
                if (colonIdx != -1) {
                  final label = line.substring(0, colonIdx).trim();
                  final value = line.substring(colonIdx + 1).trim();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 5, right: 8),
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: iconColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF333333),
                                  height: 1.4),
                              children: [
                                TextSpan(
                                  text: '$label:  ',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700),
                                ),
                                TextSpan(text: value),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                // Plain line without label
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(line,
                      style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF444444),
                          height: 1.4)),
                );
              }).toList(),
            )
          else
            Text(
              body ?? '',
              style: const TextStyle(
                  fontSize: 14, color: Color(0xFF444444), height: 1.5),
            ),
        ],
      ),
    );
  }

  // ── Chip list card ──────────────────────────────────────────
  Widget _chipCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required List<String> items,
    required Color chipColor,
    required Color chipBorder,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: iconColor)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items
                .map(
                  (item) => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: chipColor,
                      border: Border.all(color: chipBorder),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(item,
                        style: const TextStyle(fontSize: 12.5, height: 1.3)),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  // ── Add to Schedule dialog ──────────────────────────────────
  void _showAddScheduleDialog(BuildContext context) {
    final controller = TextEditingController(text: medicine.name);
    DateTime selectedDate = DateTime.now();
    int hour = 8;
    int minute = 0;
    String period = 'AM';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Add Schedule',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  const Text('Select Date'),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: selectedDate,
                        firstDate: DateTime.now()
                            .subtract(const Duration(days: 365)),
                        lastDate:
                            DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) set(() => selectedDate = picked);
                    },
                    child: _field(
                        '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
                  ),
                  const SizedBox(height: 16),
                  const Text('Time'),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _timePicker(
                          value: hour.toString().padLeft(2, '0'),
                          onTap: () async {
                            final p = await showTimePicker(
                                context: ctx,
                                initialTime:
                                    TimeOfDay(hour: hour, minute: minute));
                            if (p != null) {
                              set(() {
                                hour = p.hourOfPeriod == 0 ? 12 : p.hourOfPeriod;
                                minute = p.minute;
                                period = p.period == DayPeriod.am ? 'AM' : 'PM';
                              });
                            }
                          }),
                      const Text(':',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      _timePicker(
                          value: minute.toString().padLeft(2, '0'),
                          onTap: () async {
                            final p = await showTimePicker(
                                context: ctx,
                                initialTime:
                                    TimeOfDay(hour: hour, minute: minute));
                            if (p != null) {
                              set(() {
                                hour = p.hourOfPeriod == 0 ? 12 : p.hourOfPeriod;
                                minute = p.minute;
                                period = p.period == DayPeriod.am ? 'AM' : 'PM';
                              });
                            }
                          }),
                      _timePicker(
                          value: period,
                          onTap: () => set(
                              () => period = period == 'AM' ? 'PM' : 'AM')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Medicine'),
                  const SizedBox(height: 8),
                  Container(
                    height: 45,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _primary),
                    ),
                    child: TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                          border: InputBorder.none, isCollapsed: true),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 12),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(String text) => Container(
        height: 45,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _primary),
        ),
        child: Text(text),
      );

  Widget _timePicker({required String value, required VoidCallback onTap}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 60,
          height: 45,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _primary),
          ),
          child: Text(value,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w500)),
        ),
      );
}
