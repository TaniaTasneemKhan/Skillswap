import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/user_profile.dart';

class UserService {
  final FirebaseFirestore _db;
  final FirebaseStorage _storage;
  UserService(this._db, this._storage);

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _db.collection('users').doc(uid);

  Stream<UserProfile?> watch(String uid) => _doc(uid).snapshots().map(
      (s) => s.exists ? UserProfile.fromMap(s.id, s.data()!) : null);

  Future<void> save(UserProfile p) =>
      _doc(p.uid).set(p.toMap(), SetOptions(merge: true));

  Future<String> uploadPhoto(String uid, File file) async {
    final ref = _storage.ref('profile_photos/$uid.jpg');
    await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }

  /// Completed profiles of everyone except [myUid] (used by the matcher).
  Future<List<UserProfile>> fetchOthers(String myUid) async {
    final snap = await _db
        .collection('users')
        .where('profileComplete', isEqualTo: true)
        .limit(100)
        .get();
    return snap.docs
        .where((d) => d.id != myUid)
        .map((d) => UserProfile.fromMap(d.id, d.data()))
        .toList();
  }
}
