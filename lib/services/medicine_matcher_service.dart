import 'package:string_similarity/string_similarity.dart';
import 'package:medisafe/models/medicine.dart';

class MedicineMatcherService {
  // Threshold for similarity score (0.0 to 1.0)
  static const double _similarityThreshold = 0.65;
  static const double _highConfidenceThreshold = 0.85;

  /// Finds the most probable medicine from extracted OCR text
  /// Scores each word against candidates and returns best match with confidence
  Medicine? findMostProbableMedicine(
    String ocrText,
    List<Medicine> candidates,
  ) {
    if (candidates.isEmpty) return null;

    final words = ocrText.toLowerCase().split(RegExp(r'\s+'));
    if (words.isEmpty) return null;

    // Score each candidate medicine
    final scoredMedicines = <(Medicine, double)>[];

    for (final medicine in candidates) {
      double bestScore = 0.0;
      
      // Try matching against brand name, generic name, and full text
      final medicineName = medicine.name.toLowerCase();
      final genericName = medicine.genericName?.toLowerCase() ?? '';
      final chemicalName = medicine.chemicalName?.toLowerCase() ?? '';

      for (final word in words) {
        if (word.length < 3) continue; // Ignore very short words

        // Calculate similarity for brand name
        final brandSimilarity = StringSimilarity.compareTwoStrings(word, medicineName);
        bestScore = bestScore > brandSimilarity ? bestScore : brandSimilarity;

        // Calculate similarity for generic name if available
        if (genericName.isNotEmpty) {
          final genericSimilarity = StringSimilarity.compareTwoStrings(word, genericName);
          bestScore = bestScore > genericSimilarity ? bestScore : genericSimilarity;
        }

        // Calculate similarity for chemical name if available
        if (chemicalName.isNotEmpty) {
          final chemicalSimilarity = StringSimilarity.compareTwoStrings(word, chemicalName);
          bestScore = bestScore > chemicalSimilarity ? bestScore : chemicalSimilarity;
        }

        // Also check if word is contained as substring
        if (medicineName.contains(word) || genericName.contains(word) || chemicalName.contains(word)) {
          bestScore = 0.95; // High confidence for substring matches
        }
      }

      // Calculate phrase-level similarity (match against entire text)
      final phraseSimilarity = StringSimilarity.compareTwoStrings(ocrText.toLowerCase(), medicineName);
      bestScore = bestScore > phraseSimilarity ? bestScore : phraseSimilarity;

      if (chemicalName.isNotEmpty) {
        final chemicalPhraseSimilarity =
            StringSimilarity.compareTwoStrings(ocrText.toLowerCase(), chemicalName);
        bestScore = bestScore > chemicalPhraseSimilarity ? bestScore : chemicalPhraseSimilarity;
      }

      if (bestScore >= _similarityThreshold) {
        scoredMedicines.add((medicine, bestScore));
      }
    }

    if (scoredMedicines.isEmpty) return null;

    // Sort by score descending
    scoredMedicines.sort((a, b) => b.$2.compareTo(a.$2));

    final topMatch = scoredMedicines.first;
    final confidence = topMatch.$2;

    // Create a copy of the medicine with confidence score
    return Medicine(
      name: topMatch.$1.name,
      rxcui: topMatch.$1.rxcui,
      indicationType: topMatch.$1.indicationType,
      sideEffects: topMatch.$1.sideEffects,
      contraindications: topMatch.$1.contraindications,
      doseFormRoute: topMatch.$1.doseFormRoute,
      genericName: topMatch.$1.genericName,
      chemicalName: topMatch.$1.chemicalName,
      mechanismOfAction: topMatch.$1.mechanismOfAction,
      dosageRecommendation: topMatch.$1.dosageRecommendation,
      confidenceScore: confidence,
    );
  }

  /// Returns top N candidate matches with their similarity scores
  /// Useful for showing alternative matches to the user
  List<(Medicine, double)> findTopMatches(
    String ocrText,
    List<Medicine> candidates, {
    int topN = 3,
  }) {
    if (candidates.isEmpty) return [];

    final words = ocrText.toLowerCase().split(RegExp(r'\s+'));
    if (words.isEmpty) return [];

    final scoredMedicines = <(Medicine, double)>[];

    for (final medicine in candidates) {
      double bestScore = 0.0;
      final medicineName = medicine.name.toLowerCase();
      final genericName = medicine.genericName?.toLowerCase() ?? '';
      final chemicalName = medicine.chemicalName?.toLowerCase() ?? '';

      for (final word in words) {
        if (word.length < 3) continue;

        final brandSimilarity = StringSimilarity.compareTwoStrings(word, medicineName);
        bestScore = bestScore > brandSimilarity ? bestScore : brandSimilarity;

        if (genericName.isNotEmpty) {
          final genericSimilarity = StringSimilarity.compareTwoStrings(word, genericName);
          bestScore = bestScore > genericSimilarity ? bestScore : genericSimilarity;
        }

        if (chemicalName.isNotEmpty) {
          final chemicalSimilarity = StringSimilarity.compareTwoStrings(word, chemicalName);
          bestScore = bestScore > chemicalSimilarity ? bestScore : chemicalSimilarity;
        }

        if (medicineName.contains(word) || genericName.contains(word) || chemicalName.contains(word)) {
          bestScore = 0.95;
        }
      }

      final phraseSimilarity = StringSimilarity.compareTwoStrings(ocrText.toLowerCase(), medicineName);
      bestScore = bestScore > phraseSimilarity ? bestScore : phraseSimilarity;

      if (chemicalName.isNotEmpty) {
        final chemicalPhraseSimilarity =
            StringSimilarity.compareTwoStrings(ocrText.toLowerCase(), chemicalName);
        bestScore = bestScore > chemicalPhraseSimilarity ? bestScore : chemicalPhraseSimilarity;
      }

      scoredMedicines.add((medicine, bestScore));
    }

    // Sort by score descending and take top N
    scoredMedicines.sort((a, b) => b.$2.compareTo(a.$2));
    return scoredMedicines.take(topN).toList();
  }

  /// Calculates confidence level based on similarity score
  String getConfidenceLevel(double score) {
    if (score >= _highConfidenceThreshold) {
      return 'High (${(score * 100).toStringAsFixed(0)}%)';
    } else if (score >= 0.75) {
      return 'Medium (${(score * 100).toStringAsFixed(0)}%)';
    } else {
      return 'Low (${(score * 100).toStringAsFixed(0)}%)';
    }
  }

  /// Checks if confidence score is acceptable
  bool isHighConfidence(double score) => score >= _highConfidenceThreshold;

  /// Checks if score meets minimum threshold
  bool meetsThreshold(double score) => score >= _similarityThreshold;
}
