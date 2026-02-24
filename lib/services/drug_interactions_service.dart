import 'package:medisafe/models/drug_interaction.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DrugInteractionsService {
  static const String _rxnavBaseUrl = 'https://rxnav.nlm.nih.gov/REST';

  // Cache for interactions
  final Map<String, List<DrugInteraction>> _interactionCache = {};

  DrugInteractionsService();

  /// Checks interactions between a primary drug and a list of user medications
  /// Returns a list of drug interactions found
  Future<List<DrugInteraction>> checkInteractions({
    required String primaryDrugName,
    required String? primaryRxcui,
    required List<String> userMedications,
  }) async {
    if (userMedications.isEmpty) {
      return [];
    }

    final interactions = <DrugInteraction>[];

    try {
      // If no rxcui provided, try to get it from drug name
      String? rxcui = primaryRxcui;
      if (rxcui == null || rxcui.isEmpty) {
        rxcui = await _getRxcuiForDrugName(primaryDrugName);
      }

      if (rxcui == null || rxcui.isEmpty) {
        // Can't check interactions without rxcui
        return [];
      }

      // Get all interactions for the primary drug
      final allInteractions = await _getInteractionsFromRxNav(rxcui);

      // Filter for interactions with user's medications
      for (final userMedication in userMedications) {
        final matchingInteractions = _filterInteractionsForDrug(
          allInteractions,
          userMedication,
          primaryDrugName,
        );
        interactions.addAll(matchingInteractions);
      }

      return interactions;
    } catch (e) {
      // Return empty list if interaction check fails, but log the error
      print('Error checking interactions: $e');
      return [];
    }
  }

  /// Gets RxCUI for a drug name
  Future<String?> _getRxcuiForDrugName(String drugName) async {
    try {
      final url = Uri.parse(
        '$_rxnavBaseUrl/drugs.json?name=$drugName',
      );

      final response = await http.get(url).timeout(
        const Duration(seconds: 5),
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final drugGroup = jsonData['drugGroup'];
        
        if (drugGroup != null && drugGroup['conceptGroup'] != null) {
          final conceptGroup = (drugGroup['conceptGroup'] as List?);
          if (conceptGroup != null && conceptGroup.isNotEmpty) {
            final concepts = conceptGroup[0]['concept'] as List?;
            if (concepts != null && concepts.isNotEmpty) {
              return concepts[0]['rxcui'];
            }
          }
        }
      }
      return null;
    } catch (e) {
      print('Error fetching rxcui: $e');
      return null;
    }
  }

  /// Gets interactions from RxNav API for a given rxcui
  Future<List<Map<String, dynamic>>> _getInteractionsFromRxNav(String rxcui) async {
    try {
      final url = Uri.parse(
        '$_rxnavBaseUrl/interaction.json?rxcui=$rxcui',
      );

      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final interactionTypeGroups = 
            (jsonData['interactionTypeGroup'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        
        final interactions = <Map<String, dynamic>>[];
        for (final group in interactionTypeGroups) {
          final interactions_list = (group['interactionType'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          interactions.addAll(interactions_list);
        }

        return interactions;
      }
      return [];
    } catch (e) {
      print('Error fetching interactions from RxNav: $e');
      return [];
    }
  }

  /// Filters interactions for a specific drug
  List<DrugInteraction> _filterInteractionsForDrug(
    List<Map<String, dynamic>> allInteractions,
    String userMedication,
    String primaryDrugName,
  ) {
    final interactions = <DrugInteraction>[];
    final userMedicationLower = userMedication.toLowerCase();

    for (final interaction in allInteractions) {
      try {
        final pair = interaction['interactionPair'] as List?;
        if (pair == null || pair.isEmpty) continue;

        for (final item in pair) {
          final drug1 = (item['drug1'] as Map?)?.cast<String, dynamic>();
          final drug2 = (item['drug2'] as Map?)?.cast<String, dynamic>();

          if (drug1 == null || drug2 == null) continue;

          final drug1Name = (drug1['name'] ?? '').toString().toLowerCase();
          final drug2Name = (drug2['name'] ?? '').toString().toLowerCase();
          final description = (item['description'] ?? '').toString();

          // Check if interaction involves the user medication
          if (drug1Name.contains(userMedicationLower) || drug2Name.contains(userMedicationLower)) {
            final severity = _parseSeverity(item['severity']?.toString() ?? 'moderate');
            
            interactions.add(DrugInteraction(
              drug1: primaryDrugName,
              drug2: userMedication,
              severity: severity,
              description: description,
              mechanism: item['mechanism']?.toString(),
              management: item['action']?.toString() ?? item['management']?.toString(),
              sourceDatabase: 'RxNav',
            ));
          }
        }
      } catch (e) {
        print('Error parsing interaction data: $e');
        continue;
      }
    }

    return interactions;
  }

  /// Parses severity string to InteractionSeverity enum
  InteractionSeverity _parseSeverity(String severity) {
    final lowerSeverity = severity.toLowerCase();
    
    if (lowerSeverity.contains('contraindicated')) {
      return InteractionSeverity.contraindicated;
    } else if (lowerSeverity.contains('severe') || lowerSeverity.contains('serious')) {
      return InteractionSeverity.severe;
    } else if (lowerSeverity.contains('moderate')) {
      return InteractionSeverity.moderate;
    } else {
      return InteractionSeverity.mild;
    }
  }

  /// Clears the interaction cache
  void clearCache() {
    _interactionCache.clear();
  }
}
