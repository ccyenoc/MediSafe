import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get uid => _auth.currentUser?.uid ?? '';
  
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
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('Allergies')
        .add({
      'allergyName': allergy, 
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getAllergies() {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('Allergies')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> removeAllergy(String docId) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('Allergies')
        .doc(docId)
        .delete();
  }

  /// ==========================
  /// MEDICAL HISTORY METHODS
  /// ==========================

  Future<void> addMedicalHistory({
    required String condition,
    required DateTime diagnosedDate,
  }) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('MedicalHistory')
        .add({
      'diseaseName': condition, 
      'date': Timestamp.fromDate(diagnosedDate),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getMedicalHistory() {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('MedicalHistory')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> removeMedicalHistory(String docId) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('MedicalHistory')
        .doc(docId)
        .delete();
  }

  /// ==========================
  /// USER PROFILE STREAM
  /// ==========================

  Stream<DocumentSnapshot> getUserProfile() {
    return _firestore.collection('users').doc(uid).snapshots();
  }
}
