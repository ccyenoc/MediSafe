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
  /// USER PROFILE STREAM
  /// ==========================

  Stream<DocumentSnapshot> getUserProfile() {
    return _firestore.collection('users').doc(uid).snapshots();
  }
}
