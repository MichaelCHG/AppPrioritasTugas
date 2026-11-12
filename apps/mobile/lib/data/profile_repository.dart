import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_profile.dart';

abstract interface class ProfileRepository {
  Future<UserProfile> getProfile();
  Future<void> saveProfile(UserProfile profile);
  Future<void> deleteProfile();
}

class FirestoreProfileRepository implements ProfileRepository {
  FirestoreProfileRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> get _profileDocument {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Tidak ada akun yang sedang masuk.');
    }
    return _firestore.collection('users').doc(user.uid);
  }

  @override
  Future<UserProfile> getProfile() async {
    final snapshot = await _profileDocument.get();
    return UserProfile.fromMap(snapshot.data() ?? const {});
  }

  @override
  Future<void> saveProfile(UserProfile profile) =>
      _profileDocument.set(profile.toMap(), SetOptions(merge: true));

  @override
  Future<void> deleteProfile() => _profileDocument.delete();
}
