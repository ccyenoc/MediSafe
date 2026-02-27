class UserProfileModel {
  final String username;
  final int age;
  final List<String> allergies;
  final List<String> medicalHistory;
  final String city;
  final String country;

  const UserProfileModel({
    required this.username,
    required this.age,
    required this.allergies,
    required this.medicalHistory,
    required this.city,
    required this.country,
  });

  factory UserProfileModel.fromFirestore(Map<String, dynamic> data) {
    final location = data['location'] as Map<String, dynamic>? ?? {};
    
    int parsedAge = 0;
    if (data['age'] is int) {
      parsedAge = data['age'];
    } else if (data['age'] != null) {
      parsedAge = int.tryParse(data['age'].toString()) ?? 0;
    }

    return UserProfileModel(
      username: data['username']?.toString() ?? '',
      age: parsedAge,
      allergies: List<String>.from(data['allergies'] ?? []),
      medicalHistory: List<String>.from(data['medical_history'] ?? []),
      city: location['city']?.toString() ?? '',
      country: location['country']?.toString() ?? '',
    );
  }

  /// Returns a plain-English summary to inject into AI prompts
  String toAiContext() {
    final allergyText = allergies.isEmpty ? 'None' : allergies.join(', ');
    final historyText = medicalHistory.isEmpty ? 'None' : medicalHistory.join(', ');
    final locationText = city.isNotEmpty ? '$city, $country' : 'Unknown';

    return '''
User Health Profile:
- Age: ${age > 0 ? age : 'Unknown'}
- Known allergies: $allergyText
- Medical history: $historyText
- Location: $locationText
''';
  }
}
