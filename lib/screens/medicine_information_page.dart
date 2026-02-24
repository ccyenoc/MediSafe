import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../colors/gradient.dart';
import '../models/medicine_model.dart';
import '../services/firestore_service.dart';
import '../services/gemini_service.dart';
import '../services/notification_service.dart';
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
                          builder: (_) => const ChatbotPage(),
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

  // ── Smart Add to Schedule dialog ───────────────────────────
  void _showAddScheduleDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _SmartScheduleDialog(medicine: medicine),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Smart Schedule Dialog — full AI prefill + Firestore save
// ─────────────────────────────────────────────────────────────
class _SmartScheduleDialog extends StatefulWidget {
  final MedicineModel medicine;
  const _SmartScheduleDialog({required this.medicine});

  @override
  State<_SmartScheduleDialog> createState() => _SmartScheduleDialogState();
}

class _SmartScheduleDialogState extends State<_SmartScheduleDialog> {
  static const _primary = Color(0xFF1E3F8F);

  // Form state
  DateTime selectedDate = DateTime.now();
  int hour = 8;
  int minute = 0;
  String period = 'AM';
  int timesPerDay = 1;
  int durationDays = 7;
  // Dynamic maxes from AI — medicine-specific
  int maxTimesPerDay = 8;
  int maxDurationDays = 365;
  final noteController = TextEditingController();
  final medicineController = TextEditingController();

  // UI state
  bool isLoadingAI = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    medicineController.text = widget.medicine.name;
    _fetchAISuggestion();
  }

  @override
  void dispose() {
    noteController.dispose();
    medicineController.dispose();
    super.dispose();
  }

  Future<void> _fetchAISuggestion() async {
    try {
      // Get user age for age-aware suggestions
      int? userAge;
      try {
        final profile = await FirestoreService().getUserProfileOnce();
        userAge = profile?['age'] as int?;
      } catch (_) {}

      final suggestion = await GeminiService()
          .getScheduleSuggestion(widget.medicine, userAge);

      if (!mounted) return;
      setState(() {
        timesPerDay = (suggestion['timesPerDay'] as num?)?.toInt().clamp(1, 12) ?? 1;
        durationDays = (suggestion['durationDays'] as num?)?.toInt().clamp(1, 365) ?? 7;
        // Set the stepper max as medicine-specific: let user go up to 2× the AI suggestion
        maxTimesPerDay = (timesPerDay * 2).clamp(4, 12);
        maxDurationDays = (durationDays * 3).clamp(30, 365);
        noteController.text = suggestion['notes']?.toString() ?? '';

        // Set first dose time from suggestedTimes[0]
        final times = suggestion['suggestedTimes'] as List?;
        if (times != null && times.isNotEmpty) {
          final parts = times[0].toString().split(':');
          if (parts.length == 2) {
            final h = int.tryParse(parts[0]) ?? 8;
            final m = int.tryParse(parts[1]) ?? 0;
            period = h >= 12 ? 'PM' : 'AM';
            hour = h > 12 ? h - 12 : (h == 0 ? 12 : h);
            minute = m;
          }
        }
        isLoadingAI = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoadingAI = false);
    }
  }

  Future<void> _save() async {
    setState(() => errorMessage = null);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => errorMessage = 'You must be signed in to save a schedule.');
        return;
      }

      int finalHour = hour;
      if (period == 'PM' && hour != 12) finalHour += 12;
      if (period == 'AM' && hour == 12) finalHour = 0;

      final schedulesRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('schedules');

      // Create entries: durationDays × timesPerDay documents
      for (int day = 0; day < durationDays; day++) {
        for (int dose = 0; dose < timesPerDay; dose++) {
          // Spread doses evenly across the day
          final hoursOffset = timesPerDay > 1 ? (dose * (24 ~/ timesPerDay)) : 0;
          final doseHour = (finalHour + hoursOffset) % 24;

          final doseTime = DateTime(
            selectedDate.year,
            selectedDate.month,
            selectedDate.day + day,
            doseHour,
            minute,
          );

          if (doseTime.isAfter(DateTime.now())) {
            final docRef = await schedulesRef.add({
              'medicineName': medicineController.text.trim(),
              'notes': noteController.text.trim(),
              'time': Timestamp.fromDate(doseTime),
              'isActive': true,
              'isTaken': false,
              'isRecurring': durationDays > 1,
              'timesPerDay': timesPerDay,
              'durationDays': durationDays,
            });

            // Schedule notification separately — don't fail the whole save if it errors
            try {
              await NotificationService().scheduleNotification(
                id: docRef.id.hashCode,
                title: '💊 Time for your medicine',
                body: 'Take your ${medicineController.text.trim()} now.',
                scheduledDate: doseTime,
              );
            } catch (_) {}
          }
        }
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Schedule saved successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() => errorMessage = 'Failed to save schedule. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: ConstrainedBox(
        constraints:
            BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back),
                  ),
                  const SizedBox(width: 12),
                  const Text('Add Schedule',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),

              if (isLoadingAI) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text('Getting AI schedule suggestion...',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ] else ...[
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Medicine field
                        const Text('Medicine',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        _inputBox(
                          child: TextField(
                            controller: medicineController,
                            decoration: const InputDecoration(
                                border: InputBorder.none,
                                isCollapsed: true,
                                contentPadding: EdgeInsets.zero),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Date
                        const Text('Start Date',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now()
                                  .add(const Duration(days: 365)),
                            );
                            if (picked != null) {
                              setState(() => selectedDate = picked);
                            }
                          },
                          child: _staticBox(
                              '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
                        ),
                        const SizedBox(height: 14),

                        // First dose time
                        const Text('First Dose Time',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _timeChip(
                                hour.toString().padLeft(2, '0'), () async {
                              final p = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay(
                                      hour: hour, minute: minute));
                              if (p != null) {
                                setState(() {
                                  hour = p.hourOfPeriod == 0
                                      ? 12
                                      : p.hourOfPeriod;
                                  minute = p.minute;
                                  period =
                                      p.period == DayPeriod.am ? 'AM' : 'PM';
                                });
                              }
                            }),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 6),
                              child: Text(':',
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold)),
                            ),
                            _timeChip(
                                minute.toString().padLeft(2, '0'), () async {
                              final p = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay(
                                      hour: hour, minute: minute));
                              if (p != null) {
                                setState(() {
                                  hour = p.hourOfPeriod == 0
                                      ? 12
                                      : p.hourOfPeriod;
                                  minute = p.minute;
                                  period =
                                      p.period == DayPeriod.am ? 'AM' : 'PM';
                                });
                              }
                            }),
                            const SizedBox(width: 8),
                            _timeChip(
                                period,
                                () => setState(() =>
                                    period = period == 'AM' ? 'PM' : 'AM')),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Times per day stepper
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Text('Times per day',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text('AI',
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: _primary,
                                          fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            _stepper(
                              value: timesPerDay,
                              min: 1,
                              max: maxTimesPerDay,
                              onChanged: (v) => setState(() => timesPerDay = v),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Duration stepper
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Text('Duration (days)',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text('AI',
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: _primary,
                                          fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            _stepper(
                              value: durationDays,
                              min: 1,
                              max: maxDurationDays,
                              onChanged: (v) =>
                                  setState(() => durationDays = v),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Notes
                        Row(
                          children: [
                            const Text('Notes',
                                style: TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text('AI',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: _primary,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        _inputBox(
                          child: TextField(
                            controller: noteController,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isCollapsed: true,
                              contentPadding: EdgeInsets.zero,
                              hintText: 'e.g. Take after meals',
                            ),
                          ),
                        ),

                        // Error
                        if (errorMessage != null) ...[
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(errorMessage!,
                                style: const TextStyle(
                                    color: Colors.red, fontSize: 13)),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: isLoadingAI ? null : _save,
                  child: const Text('Save Schedule',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Helper widgets ──────────────────────────────────────────
  Widget _inputBox({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _primary),
        ),
        child: child,
      );

  Widget _staticBox(String text) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _primary),
        ),
        child: Text(text),
      );

  Widget _timeChip(String value, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 56,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _primary),
          ),
          child:
              Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ),
      );

  Widget _stepper({
    required int value,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
  }) =>
      Row(
        children: [
          GestureDetector(
            onTap: value > min ? () => onChanged(value - 1) : null,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: value > min ? _primary : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.remove, color: Colors.white, size: 16),
            ),
          ),
          Container(
            width: 44,
            alignment: Alignment.center,
            child: Text('$value',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          GestureDetector(
            onTap: value < max ? () => onChanged(value + 1) : null,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: value < max ? _primary : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 16),
            ),
          ),
        ],
      );
}
