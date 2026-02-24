class Medicine {
  final String name;
  final String? rxcui; // RxNorm Concept Unique Identifier
  final String? indicationType;
  final List<String> sideEffects;
  final List<String> contraindications;
  final String? doseFormRoute;
  final String? genericName;
  final String? chemicalName;
  final String? mechanismOfAction;
  final String? dosageRecommendation;
  final double? confidenceScore; // From OCR matching

  Medicine({
    required this.name,
    this.rxcui,
    this.indicationType,
    this.sideEffects = const [],
    this.contraindications = const [],
    this.doseFormRoute,
    this.genericName,
    this.chemicalName,
    this.mechanismOfAction,
    this.dosageRecommendation,
    this.confidenceScore,
  });

  factory Medicine.fromJson(Map<String, dynamic> json) {
    return Medicine(
      name: json['name'] ?? json['propertyName'] ?? '',
      rxcui: json['rxcui']?.toString(),
      indicationType: json['indicationType'],
      sideEffects: List<String>.from(json['sideEffects'] ?? []),
      contraindications: List<String>.from(json['contraindications'] ?? []),
      doseFormRoute: json['doseFormRoute'],
      genericName: json['genericName'],
      chemicalName: json['chemicalName'],
      mechanismOfAction: json['mechanismOfAction'],
      dosageRecommendation: json['dosageRecommendation'],
      confidenceScore: (json['confidenceScore'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'rxcui': rxcui,
      'indicationType': indicationType,
      'sideEffects': sideEffects,
      'contraindications': contraindications,
      'doseFormRoute': doseFormRoute,
      'genericName': genericName,
      'chemicalName': chemicalName,
      'mechanismOfAction': mechanismOfAction,
      'dosageRecommendation': dosageRecommendation,
      'confidenceScore': confidenceScore,
    };
  }

  @override
  String toString() => 'Medicine(name: $name, rxcui: $rxcui)';
}
