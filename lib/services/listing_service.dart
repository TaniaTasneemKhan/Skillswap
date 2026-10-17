import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/skill_listing.dart';

class ListingService {
  final FirebaseFirestore _db;
  ListingService(this._db);

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('listings');

  Stream<List<SkillListing>> watchAll() => _col
      .orderBy('createdAt', descending: true)
      .limit(100)
      .snapshots()
      .map((s) => s.docs.map(SkillListing.fromDoc).toList());

  Future<void> add(SkillListing l) => _col.add(l.toMap());

  Future<void> delete(String id) => _col.doc(id).delete();
}
