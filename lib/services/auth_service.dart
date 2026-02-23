import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> registerUser({
    required String email,
    required String password,
    required String username,
  }) async {
    UserCredential credential =
        await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    String uid = credential.user!.uid;

    await _firestore.collection('users').doc(uid).set({
      'email': email,
      'username': username,
      'age': 0,
      'created_at': Timestamp.now(),
      'allergies': [],
      'medical_history': [],
      'location': {
        'city': '',
        'country': '',
        'lat': null,
        'lng': null,
      },
    });
  }
}
