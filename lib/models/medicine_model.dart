class MedicineModel {
  final String name;
  final String shortDescription;
  final String function;
  final String dosage;
  final List<String> sideEffects;
  final List<String> recipients;
  final List<String> contraindications;
  final List<String> allergies;
  final String personalizedWarning;
  final String rawOcrText;

  const MedicineModel({
    required this.name,
    required this.shortDescription,
    required this.function,
    required this.dosage,
    required this.sideEffects,
    required this.recipients,
    required this.contraindications,
    required this.allergies,
    this.personalizedWarning = '',
    this.rawOcrText = '',
  });

  factory MedicineModel.fromJson(Map<String, dynamic> json) {
    return MedicineModel(
      name: json['name'] ?? 'Unknown Medicine',
      shortDescription: json['shortDescription'] ?? '',
      function: json['function'] ?? '',
      dosage: json['dosage'] ?? '',
      sideEffects: List<String>.from(json['sideEffects'] ?? []),
      recipients: List<String>.from(json['recipients'] ?? []),
      contraindications: List<String>.from(json['contraindications'] ?? []),
      allergies: List<String>.from(json['allergies'] ?? []),
      personalizedWarning: _parseWarning(json['personalizedWarning']),
    );
  }

  /// Handles personalizedWarning being a String OR a List (AI sometimes returns a list)
  static String _parseWarning(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is List) return value.map((e) => e.toString()).join('\n');
    return value.toString();
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'shortDescription': shortDescription,
      'function': function,
      'dosage': dosage,
      'sideEffects': sideEffects,
      'recipients': recipients,
      'contraindications': contraindications,
      'allergies': allergies,
      'personalizedWarning': personalizedWarning,
    };
  }

  /// Fallback model shown when medicine cannot be identified
  factory MedicineModel.unknown(String rawOcrText) {
    return MedicineModel(
      name: 'Unknown Medicine',
      shortDescription: 'Could not identify this medicine from the label.',
      function: 'N/A',
      dosage: 'N/A',
      sideEffects: [],
      recipients: [],
      contraindications: [],
      allergies: [],
      personalizedWarning: '',
      rawOcrText: rawOcrText,
    );
  }
}
