import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get uid => _auth.currentUser!.uid;

  /// ==========================
  /// SCHEDULE METHODS
  /// ==========================

  Future<void> addSchedule({
    required String medicineName,
    required String dose,
    required DateTime date,
    required String time,
    String? notes,
  }) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('schedules')
        .add({
      'medicine_name': medicineName,
      'dose': dose,
      'date': Timestamp.fromDate(date),
      'time': time,
      'notes': notes ?? '',
      'is_active': true,
      'created_at': Timestamp.now(),
    });
  }

  Stream<QuerySnapshot> getSchedules() {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('schedules')
        .orderBy('date')
        .snapshots();
  }

  Future<void> deleteSchedule(String scheduleId) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('schedules')
        .doc(scheduleId)
        .delete();
  }

  /// ==========================
  /// ALLERGIES METHODS
  /// ==========================

  Future<void> addAllergy(String allergy) async {
    await _firestore.collection('users').doc(uid).update({
      'allergies': FieldValue.arrayUnion([allergy])
    });
  }

  Future<void> removeAllergy(String allergy) async {
    await _firestore.collection('users').doc(uid).update({
      'allergies': FieldValue.arrayRemove([allergy])
    });
  }

  /// ==========================
  /// MEDICAL HISTORY METHODS
  /// ==========================

  Future<void> addMedicalHistory(String condition) async {
    await _firestore.collection('users').doc(uid).update({
      'medical_history': FieldValue.arrayUnion([condition])
    });
  }

  Future<void> removeMedicalHistory(String condition) async {
    await _firestore.collection('users').doc(uid).update({
      'medical_history': FieldValue.arrayRemove([condition])
    });
  }

  /// ==========================
  /// USER PROFILE
  /// ==========================

  Stream<DocumentSnapshot> getUserProfile() {
    return _firestore.collection('users').doc(uid).snapshots();
  }

  /// One-time profile fetch for AI use — reads parent doc + sub-collections
  Future<Map<String, dynamic>?> getUserProfileOnce() async {
    final userRef = _firestore.collection('users').doc(uid);
    final doc = await userRef.get();
    if (!doc.exists) return null;

    final data = Map<String, dynamic>.from(doc.data() ?? {});

    // Fetch MedicalHistory sub-collection (saved by optional_info_page)
    try {
      final historySnap = await userRef.collection('MedicalHistory').get();
      final conditions = historySnap.docs
          .map((d) => d.data()['diseaseName']?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
      // Merge with any existing top-level medical_history array (older saves)
      final existing = List<String>.from(data['medical_history'] ?? []);
      final merged = {...existing, ...conditions}.toList();
      data['medical_history'] = merged;
    } catch (_) {}

    // Fetch Allergies sub-collection (saved by optional_info_page)
    try {
      final allergySnap = await userRef.collection('Allergies').get();
      final allergies = allergySnap.docs
          .map((d) => d.data()['allergyName']?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
      // Merge with any existing top-level allergies array (older saves)
      final existing = List<String>.from(data['allergies'] ?? []);
      final merged = {...existing, ...allergies}.toList();
      data['allergies'] = merged;
    } catch (_) {}

    return data;
  }


  /// ==========================
  /// AGE METHOD
  /// ==========================

  Future<void> updateAge(int age) async {
    await _firestore.collection('users').doc(uid).update({'age': age});
  }

  Future<void> updateProfileBasicInfo(String username, int age, String? base64Image) async {
    final data = <String, dynamic>{
      'username': username,
      'age': age,
    };
    if (base64Image != null) {
      data['profile_pic_base64'] = base64Image;
    }
    await _firestore.collection('users').doc(uid).update(data);
  }

  /// ==========================
  /// LOCATION METHOD
  /// ==========================

  Future<void> updateLocation({
    required String city,
    required String country,
    required double lat,
    required double lng,
  }) async {
    await _firestore.collection('users').doc(uid).update({
      'location': {
        'city': city,
        'country': country,
        'lat': lat,
        'lng': lng,
      }
    });
  }

  /// ==========================
  /// SCAN HISTORY METHODS
  /// ==========================

  /// Saves a successful scan to Firestore for the schedule scan-history picker.
  Future<void> saveScanHistory({
    required String medicineName,
    required String shortDesc,
    String? imagePath,
  }) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('scan_history')
        .add({
      'medicineName': medicineName,
      'shortDesc': shortDesc,
      'imagePath': imagePath ?? '',
      'scannedAt': Timestamp.now(),
    });
  }

  /// Returns the 20 most recent scans, newest first.
  Stream<QuerySnapshot> getScanHistory() {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('scan_history')
        .orderBy('scannedAt', descending: true)
        .limit(20)
        .snapshots();
  }
}
