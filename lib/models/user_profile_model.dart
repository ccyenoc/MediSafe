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
    return UserProfileModel(
      username: data['username'] ?? '',
      age: (data['age'] ?? 0) as int,
      allergies: List<String>.from(data['allergies'] ?? []),
      medicalHistory: List<String>.from(data['medical_history'] ?? []),
      city: location['city'] ?? '',
      country: location['country'] ?? '',
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
