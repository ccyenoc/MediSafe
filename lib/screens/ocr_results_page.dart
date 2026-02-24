import 'dart:io';
import 'package:flutter/material.dart';
import '../models/medicine.dart';
import '../models/drug_interaction.dart';
import '../services/fda_api_service.dart';
import '../services/firestore_service.dart';
import '../services/drug_interactions_service.dart';
import '../colors/color.dart';

class OcrResultsPage extends StatefulWidget {
  final String extractedText;
  final Medicine? matchedMedicine;
  final List<Medicine> alternativeMedicines;
  final List<String> userCurrentMedications;
  final File imageFile;
  final FdaApiService fdaApiService;
  final FirestoreService firestoreService;

  const OcrResultsPage({
    super.key,
    required this.extractedText,
    required this.matchedMedicine,
    required this.alternativeMedicines,
    required this.userCurrentMedications,
    required this.imageFile,
    required this.fdaApiService,
    required this.firestoreService,
  });

  @override
  State<OcrResultsPage> createState() => _OcrResultsPageState();
}

class _OcrResultsPageState extends State<OcrResultsPage> {
  late DrugInteractionsService _interactionsService;
  List<DrugInteraction> _interactions = [];
  bool _showRawText = false;
  String? _selectedMedicineName;

  @override
  void initState() {
    super.initState();
    _interactionsService = DrugInteractionsService();
    _selectedMedicineName = widget.matchedMedicine?.name;
    if (widget.matchedMedicine != null && widget.userCurrentMedications.isNotEmpty) {
      _checkInteractions();
    }
  }

  Future<void> _checkInteractions() async {
    if (widget.matchedMedicine == null) return;

    try {
      final interactions = await _interactionsService.checkInteractions(
        primaryDrugName: widget.matchedMedicine!.name,
        primaryRxcui: widget.matchedMedicine!.rxcui,
        userMedications: widget.userCurrentMedications,
      );

      if (mounted) {
        setState(() {
          _interactions = interactions;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error checking interactions: $e')),
        );
      }
    }
  }

  Future<void> _addToSchedule() async {
    if (_selectedMedicineName == null || _selectedMedicineName!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a medicine')),
      );
      return;
    }

    // Show dialog to get dosage and timing
    showDialog(
      context: context,
      builder: (context) => _AddScheduleDialog(
        medicineName: _selectedMedicineName!,
        firestoreService: widget.firestoreService,
      ),
    ).then((added) {
      if (added == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Medicine added to schedule')),
        );
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) Navigator.pop(context);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final medicine = widget.matchedMedicine;
    final hasInteractions = _interactions.isNotEmpty;
    final hasSevereInteractions =
        _interactions.any((i) => i.severity == InteractionSeverity.severe ||
            i.severity == InteractionSeverity.contraindicated);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.darkBlue,
        title: const Text('Medicine Information'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Medicine match result card
            if (medicine != null)
              Container(
                color: AppColors.blue2.withValues(alpha: 0.1),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                medicine.name,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.darkBlue,
                                ),
                              ),
                              if (medicine.genericName != null)
                                Text(
                                  'Generic: ${medicine.genericName}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (medicine.confidenceScore != null)
                          Column(
                            children: [
                              const Text(
                                'Match',
                                style: TextStyle(fontSize: 12),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: ShapeDecoration(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  color: _getConfidenceColor(
                                    medicine.confidenceScore!,
                                  ),
                                ),
                                child: Text(
                                  '${(medicine.confidenceScore! * 100).toStringAsFixed(0)}%',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.orange, width: 2),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.orange.withValues(alpha: 0.1),
                  ),
                  child: const Text(
                    'No medicine match found. Please select from alternatives or search manually.',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ),
            // Drug interactions warnings
            if (hasInteractions)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          hasSevereInteractions
                              ? Icons.warning_amber_rounded
                              : Icons.info_outline,
                          color: hasSevereInteractions
                              ? Colors.red
                              : Colors.orange,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          hasSevereInteractions
                              ? 'Potential Drug Interactions Found'
                              : 'Possible Interactions',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: hasSevereInteractions
                                ? Colors.red
                                : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ..._interactions.map((interaction) {
                      final severityColor =
                          _getSeverityColor(interaction.severity);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: severityColor, width: 1),
                          borderRadius: BorderRadius.circular(8),
                          color: severityColor.withValues(alpha: 0.05),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: severityColor,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    interaction.severity.displayName
                                        .toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${interaction.drug1} + ${interaction.drug2}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              interaction.description,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                              ),
                            ),
                            if (interaction.management != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Management:',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      interaction.management!,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            // Medicine details
            if (medicine != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (medicine.indicationType != null)
                      _buildDetailSection(
                        title: 'Indication',
                        content: medicine.indicationType!,
                      ),
                    if (medicine.dosageRecommendation != null)
                      _buildDetailSection(
                        title: 'Dosage',
                        content: medicine.dosageRecommendation!,
                      ),
                    if (medicine.doseFormRoute != null)
                      _buildDetailSection(
                        title: 'Form & Route',
                        content: medicine.doseFormRoute!,
                      ),
                    if (medicine.sideEffects.isNotEmpty)
                      _buildDetailSection(
                        title: 'Side Effects',
                        content: medicine.sideEffects.join(', '),
                      ),
                    if (medicine.contraindications.isNotEmpty)
                      _buildDetailSection(
                        title: 'Contraindications',
                        content: medicine.contraindications.join(', '),
                        highlight: true,
                      ),
                  ],
                ),
              ),
            // Extracted text section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Extracted Text',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      GestureDetector(
                        onTap: () =>
                            setState(() => _showRawText = !_showRawText),
                        child: Text(
                          _showRawText ? 'Hide' : 'Show',
                          style: const TextStyle(
                            color: AppColors.blue2,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_showRawText)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border:
                            Border.all(color: Colors.grey[300]!, width: 1),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey[50],
                      ),
                      child: Text(
                        widget.extractedText,
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Alternative medicines
            if (widget.alternativeMedicines.isNotEmpty &&
                medicine == null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Possible Matches',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...widget.alternativeMedicines
                        .take(3)
                        .map((med) {
                          final isSelected = _selectedMedicineName == med.name;
                          return GestureDetector(
                            onTap: () => setState(
                                () => _selectedMedicineName = med.name),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.blue2
                                      : Colors.grey[300]!,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                color: isSelected
                                    ? AppColors.blue2.withValues(alpha: 0.1)
                                    : Colors.transparent,
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    med.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (med.genericName != null)
                                    Text(
                                      'Generic: ${med.genericName}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        })
                        .toList(),
                  ],
                ),
              ),
            // Action buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.blue2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed:
                          _selectedMedicineName != null ? _addToSchedule : null,
                      child: const Text(
                        'Add to Schedule',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: AppColors.blue2,
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Scan Again',
                        style: TextStyle(
                          color: AppColors.blue2,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection({
    required String title,
    required String content,
    bool highlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: AppColors.darkBlue,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(
                color: highlight ? Colors.orange : Colors.grey[300]!,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(8),
              color: highlight
                  ? Colors.orange.withValues(alpha: 0.05)
                  : Colors.grey[50],
            ),
            child: Text(
              content,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getConfidenceColor(double score) {
    if (score >= 0.85) return Colors.green;
    if (score >= 0.75) return Colors.orange;
    return Colors.red;
  }

  Color _getSeverityColor(InteractionSeverity severity) {
    switch (severity) {
      case InteractionSeverity.mild:
        return Colors.yellow[700]!;
      case InteractionSeverity.moderate:
        return Colors.orange;
      case InteractionSeverity.severe:
        return Colors.deepOrange;
      case InteractionSeverity.contraindicated:
        return Colors.red;
    }
  }
}

class _AddScheduleDialog extends StatefulWidget {
  final String medicineName;
  final FirestoreService firestoreService;

  const _AddScheduleDialog({
    required this.medicineName,
    required this.firestoreService,
  });

  @override
  State<_AddScheduleDialog> createState() => _AddScheduleDialogState();
}

class _AddScheduleDialogState extends State<_AddScheduleDialog> {
  late TextEditingController _doseController;
  late TextEditingController _timeController;
  late TextEditingController _notesController;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _doseController = TextEditingController();
    _timeController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _doseController.dispose();
    _timeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time != null) {
      setState(() {
        _timeController.text = time.format(context);
      });
    }
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _addSchedule() async {
    if (_doseController.text.isEmpty || _timeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    try {
      await widget.firestoreService.addSchedule(
        medicineName: widget.medicineName,
        dose: _doseController.text,
        date: _selectedDate,
        time: _timeController.text,
        notes: _notesController.text,
      );

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding schedule: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add ${widget.medicineName} to Schedule'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _doseController,
              decoration: const InputDecoration(
                labelText: 'Dose (required)',
                hintText: 'e.g., 500mg, 1 tablet',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _timeController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Time (required)',
                suffixIcon: const Icon(Icons.schedule),
              ),
              onTap: _selectTime,
            ),
            const SizedBox(height: 12),
            TextField(
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Date',
                hintText: _selectedDate.toString().split(' ')[0],
                suffixIcon: const Icon(Icons.calendar_today),
              ),
              controller: TextEditingController(
                text: _selectedDate.toString().split(' ')[0],
              ),
              onTap: _selectDate,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'Take with food, etc.',
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _addSchedule,
          child: const Text('Add'),
        ),
      ],
    );
  }
}
