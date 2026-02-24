enum InteractionSeverity {
  mild,      // Unlikely to cause problems
  moderate,  // Increased risk
  severe,    // Significant problems, use with caution
  contraindicated; // Should not be used together

  String get displayName {
    switch (this) {
      case InteractionSeverity.mild:
        return 'Mild';
      case InteractionSeverity.moderate:
        return 'Moderate';
      case InteractionSeverity.severe:
        return 'Severe';
      case InteractionSeverity.contraindicated:
        return 'Contraindicated';
    }
  }

  String get color {
    switch (this) {
      case InteractionSeverity.mild:
        return 'yellow'; // #FFC107
      case InteractionSeverity.moderate:
        return 'orange'; // #FF9800
      case InteractionSeverity.severe:
        return 'deepOrange'; // #FF5722
      case InteractionSeverity.contraindicated:
        return 'red'; // #F44336
    }
  }
}

class DrugInteraction {
  final String drug1; // First drug name
  final String drug2; // Second drug name
  final InteractionSeverity severity;
  final String description;
  final String? mechanism; // How the interaction works
  final String? management; // How to manage the interaction
  final String? sourceDatabase; // Where the data came from (e.g., 'RxNav')

  DrugInteraction({
    required this.drug1,
    required this.drug2,
    required this.severity,
    required this.description,
    this.mechanism,
    this.management,
    this.sourceDatabase,
  });

  factory DrugInteraction.fromJson(Map<String, dynamic> json) {
    final severityStr = (json['severity'] as String?)?.toLowerCase() ?? 'moderate';
    InteractionSeverity severity;
    
    if (severityStr.contains('contraindicated')) {
      severity = InteractionSeverity.contraindicated;
    } else if (severityStr.contains('severe') || severityStr.contains('significant')) {
      severity = InteractionSeverity.severe;
    } else if (severityStr.contains('moderate')) {
      severity = InteractionSeverity.moderate;
    } else {
      severity = InteractionSeverity.mild;
    }

    return DrugInteraction(
      drug1: json['drug1'] ?? '',
      drug2: json['drug2'] ?? '',
      severity: severity,
      description: json['description'] ?? '',
      mechanism: json['mechanism'],
      management: json['management'],
      sourceDatabase: json['sourceDatabase'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'drug1': drug1,
      'drug2': drug2,
      'severity': severity.displayName,
      'description': description,
      'mechanism': mechanism,
      'management': management,
      'sourceDatabase': sourceDatabase,
    };
  }

  @override
  String toString() =>
      'DrugInteraction(drug1: $drug1, drug2: $drug2, severity: ${severity.displayName})';
}
