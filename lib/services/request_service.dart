import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/exchange_request.dart';
import 'chat_service.dart';

class RequestService {
  final FirebaseFirestore _db;
  RequestService(this._db);

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('requests');

  /// All requests the user sent or received, newest first.
  Stream<List<ExchangeRequest>> watchMine(String uid) => _col
      .where('participants', arrayContains: uid)
      .snapshots()
      .map((s) {
        final list = s.docs.map(ExchangeRequest.fromDoc).toList();
        final now = DateTime.now();
        list.sort((a, b) => (b.createdAt ?? now).compareTo(a.createdAt ?? now));
        return list;
      });

  Future<void> send(ExchangeRequest r) => _col.add(r.toMap());

  /// Accepting also creates the shared chat, atomically.
  Future<void> accept(ExchangeRequest r) {
    final chatId = ChatService.chatIdFor(r.fromId, r.toId);
    final batch = _db.batch()
      ..update(_col.doc(r.id), {
        'status': 'accepted',
        'chatId': chatId,
        'respondedAt': FieldValue.serverTimestamp(),
      })
      ..set(
        _db.collection('chats').doc(chatId),
        {
          'participants': [r.fromId, r.toId],
          'participantNames': {r.fromId: r.fromName, r.toId: r.toName},
          'participantPhotos': {r.fromId: r.fromPhotoUrl, r.toId: r.toPhotoUrl},
          'requestId': r.id,
          'createdAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    return batch.commit();
  }

  Future<void> reject(ExchangeRequest r) => _col.doc(r.id).update({
        'status': 'rejected',
        'respondedAt': FieldValue.serverTimestamp(),
      });

  /// Sender withdraws a request that is still pending.
  Future<void> cancel(ExchangeRequest r) => _col.doc(r.id).update({
        'status': 'cancelled',
        'respondedAt': FieldValue.serverTimestamp(),
      });
}
