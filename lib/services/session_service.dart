import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/session.dart';

class SessionService {
  final FirebaseFirestore _db;
  SessionService(this._db);

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('sessions');

  /// All my sessions, soonest first.
  Stream<List<Session>> watchMine(String uid) => _col
      .where('participants', arrayContains: uid)
      .snapshots()
      .map((s) {
        final list = s.docs.map(Session.fromDoc).toList();
        list.sort((a, b) => a.startAt.compareTo(b.startAt));
        return list;
      });

  Future<void> propose(Session s) => _col.add(s.toMap());

  Future<void> _setStatus(Session s, String status, String by) => _col.doc(s.id).update({
        'status': status,
        'updatedBy': by,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> confirm(Session s, String by) => _setStatus(s, 'confirmed', by);
  Future<void> decline(Session s, String by) => _setStatus(s, 'declined', by);
  Future<void> cancel(Session s, String by) => _setStatus(s, 'cancelled', by);
  Future<void> complete(Session s, String by) => _setStatus(s, 'completed', by);
}
