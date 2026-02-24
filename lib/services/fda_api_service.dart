import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:medisafe/models/medicine.dart';
import 'package:string_similarity/string_similarity.dart';

class FdaApiService {
  static const String _baseUrl = 'https://api.fda.gov/drug/label.json';
  static const String _rxnavBaseUrl = 'https://rxnav.nlm.nih.gov/REST';
  static const double _chemicalMatchThreshold = 0.75;

  static bool _chemicalIndexLoaded = false;
  static Future<void>? _chemicalIndexLoading;
  static final Map<String, List<String>> _chemicalNameIndex = {};
  
  // Simple in-memory cache for medicine data
  final Map<String, Medicine> _medicineCache = {};
  final Map<String, List<Medicine>> _searchCache = {};

  /// Searches for medicines by name using OpenFDA API
  /// Returns a list of matching medicines
  Future<List<Medicine>> searchMedicine(String medicineName) async {
    // Check cache first
    if (_searchCache.containsKey(medicineName)) {
      return _searchCache[medicineName]!;
    }

    try {
      // Use OpenFDA endpoint to search by drug name
        // Use OpenFDA endpoint to search by drug and substance names
        final query =
            'openfda.generic_name:\"$medicineName\" OR '
            'openfda.brand_name:\"$medicineName\" OR '
            'openfda.substance_name:\"$medicineName\" OR '
            'active_ingredient:\"$medicineName\"';
      final url = Uri.parse(
        '$_baseUrl?search=$query&limit=10',
      );

      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('OpenFDA API request timed out'),
      );

      print('OpenFDA response (${response.statusCode}): ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final results = (jsonData['results'] as List?)?.cast<Map<String, dynamic>>() ?? [];

        final medicines = <Medicine>[];
        for (final result in results) {
          try {
            final medicine = _parseOpenFdaDrug(result);
            medicines.add(medicine);
            _medicineCache[medicine.name.toLowerCase()] = medicine;
          } catch (e) {
            // Skip malformed entries
            continue;
          }
        }

        _searchCache[medicineName] = medicines;
        return medicines;
      } else if (response.statusCode == 404) {
        return [];
      } else {
        throw Exception('Failed to search medicines: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Medicine search failed: ${e.toString()}');
    }
  }

  /// Gets detailed medicine information by RxCUI (RxNorm Concept ID)
  /// Uses NIH RxNav API for comprehensive drug data
  Future<Medicine?> getMedicineDetailsByRxcui(String rxcui) async {
    final cacheKey = 'rxcui_$rxcui';
    if (_medicineCache.containsKey(cacheKey)) {
      return _medicineCache[cacheKey];
    }

    try {
      final url = Uri.parse(
        '$_rxnavBaseUrl/rxcui/$rxcui/properties.json?allProperties=true',
      );

      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
      );

      print('RxNav properties response (${response.statusCode}): ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final properties = jsonData['properties'];

        if (properties != null) {
          final medicine = Medicine(
            name: properties['name'] ?? 'Unknown',
            rxcui: rxcui,
            genericName: properties['rxcui']?.toString(),
          );
          _medicineCache[cacheKey] = medicine;
          return medicine;
        }
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch medicine details: ${e.toString()}');
    }
  }

  /// Gets drug interactions from RxNav API
  /// Returns a list of drug interaction summaries
  Future<List<Map<String, dynamic>>> getInteractionsForDrug(String rxcui) async {
    try {
      final url = Uri.parse(
        '$_rxnavBaseUrl/interaction.json?rxcui=$rxcui',
      );

      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
      );

      print('RxNav interactions response (${response.statusCode}): ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final interactions = (jsonData['interactionTypeGroup'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        return interactions;
      }
      return [];
    } catch (e) {
      throw Exception('Failed to fetch interactions: ${e.toString()}');
    }
  }

  Future<String?> resolveChemicalNameFromOcr({
    required List<String> candidates,
    String? fullText,
  }) async {
    try {
      await _ensureChemicalIndexLoaded();
    } catch (_) {
      return null;
    }

    final inputs = <String>{};
    for (final candidate in candidates) {
      final normalized = _normalizeChemicalName(candidate);
      if (normalized.length >= 3) {
        inputs.add(normalized);
      }
    }

    if (fullText != null) {
      final normalized = _normalizeChemicalName(fullText);
      if (normalized.length >= 3) {
        inputs.add(normalized);
      }
    }

    String? bestMatch;
    double bestScore = 0.0;

    for (final input in inputs) {
      final indexKey = _chemicalIndexKey(input);
      var bucket = _chemicalNameIndex[indexKey] ?? [];
      if (bucket.isEmpty && indexKey.length > 1) {
        bucket = _chemicalNameIndex[indexKey.substring(0, 1)] ?? [];
      }

      for (final name in bucket) {
        if ((name.length - input.length).abs() > 12 &&
            !name.contains(input) &&
            !input.contains(name)) {
          continue;
        }

        var score = StringSimilarity.compareTwoStrings(input, name);
        if (name.contains(input) || input.contains(name)) {
          score = 0.95;
        }

        if (score > bestScore) {
          bestScore = score;
          bestMatch = name;
        }
      }
    }

    if (bestScore >= _chemicalMatchThreshold) {
      return bestMatch;
    }

    return null;
  }

  /// Parses OpenFDA drug label response
  Medicine _parseOpenFdaDrug(Map<String, dynamic> result) {
    final openFda = result['openfda'] as Map<String, dynamic>? ?? {};
    
    final name = (openFda['brand_name'] as List?)?.first ??
        (openFda['generic_name'] as List?)?.first ??
        'Unknown Medicine';
    
    final genericName = (openFda['generic_name'] as List?)?.first;
    final chemicalName = (openFda['substance_name'] as List?)?.first ??
      (result['active_ingredient'] as List?)?.first ??
      (result['active_ingredient'] as String?);
    final rxcui = _extractRxcui(openFda);
    
    // Parse side effects from warnings
    final warnings = (result['warnings'] as List?)?.cast<String>() ?? [];
    final sideEffects = (result['adverse_reactions'] as List?)?.cast<String>() ?? [];
    
    // Parse contraindications
    final contraindications = ((result['contraindications'] as List?)?.cast<String>() ?? [])
        .followedBy(warnings)
        .toList();

    // Parse dosage info
    final dosageRecommendation = result['dosage_and_administration'] as String?;
    final doseFormRoute = (openFda['route'] as List?)?.join(', ');

    // Get indication (use of the drug)
    final indicationType = (result['indications_and_usage'] as String?)?.split('\n').first;

    return Medicine(
      name: name,
      rxcui: rxcui,
      genericName: genericName,
      chemicalName: chemicalName,
      indicationType: indicationType,
      sideEffects: sideEffects.take(5).toList(), // Limit to first 5
      contraindications: contraindications.take(5).toList(),
      doseFormRoute: doseFormRoute,
      dosageRecommendation: dosageRecommendation,
      mechanismOfAction: result['mechanism_of_action'] as String?,
    );
  }

  /// Extracts RxCUI from OpenFDA response
  String? _extractRxcui(Map<String, dynamic> openFda) {
    final rxcuis = openFda['rxcui'] as List?;
    if (rxcuis != null && rxcuis.isNotEmpty) {
      return rxcuis.first.toString();
    }
    return null;
  }

  Future<void> _ensureChemicalIndexLoaded() async {
    if (_chemicalIndexLoaded) return;

    if (_chemicalIndexLoading != null) {
      await _chemicalIndexLoading;
      return;
    }

    _chemicalIndexLoading = _loadChemicalIndex();
    await _chemicalIndexLoading;
    _chemicalIndexLoading = null;
  }

  Future<void> _loadChemicalIndex() async {
    try {
      final url = Uri.parse('$_rxnavBaseUrl/allconcepts.json?tty=IN');
      final response = await http.get(url).timeout(
        const Duration(seconds: 30),
      );

      print(
        'RxNav ingredients response (${response.statusCode}) size=${response.body.length}',
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch RxNav ingredient list');
      }

      final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
      final group = jsonData['minConceptGroup'] as Map<String, dynamic>?;
      final concepts = (group?['minConcept'] as List?)?.cast<Map<String, dynamic>>() ?? [];

      for (final concept in concepts) {
        final name = concept['name']?.toString();
        if (name == null || name.isEmpty) continue;

        final normalized = _normalizeChemicalName(name);
        if (normalized.isEmpty) continue;

        final key = _chemicalIndexKey(normalized);
        final bucket = _chemicalNameIndex.putIfAbsent(key, () => []);
        bucket.add(normalized);
      }

      _chemicalIndexLoaded = true;
    } catch (e) {
      _chemicalIndexLoaded = false;
      print('Error loading RxNav ingredient list: $e');
      rethrow;
    }
  }

  String _chemicalIndexKey(String name) {
    if (name.length >= 2) {
      return name.substring(0, 2);
    }
    return name.substring(0, 1);
  }

  String _normalizeChemicalName(String name) {
    var value = name.toLowerCase();
    value = value.replaceAll(RegExp(r'[^a-z0-9\s\-]'), ' ');
    value = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    return value;
  }

  /// Clears the cache
  void clearCache() {
    _medicineCache.clear();
    _searchCache.clear();
  }
}
