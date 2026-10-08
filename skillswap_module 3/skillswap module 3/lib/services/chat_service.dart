import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/chat.dart';

class ChatService {
  final FirebaseFirestore _db;
  ChatService(this._db);

  CollectionReference<Map<String, dynamic>> get _chats => _db.collection('chats');

  /// Same id for both users regardless of who asks -> one chat per pair.
  static String chatIdFor(String a, String b) {
    final ids = [a, b]..sort();
    return ids.join('_');
  }

  Stream<List<ChatSummary>> watchMine(String uid) => _chats
      .where('participants', arrayContains: uid)
      .snapshots()
      .map((s) {
        final list = s.docs.map(ChatSummary.fromDoc).toList();
        final now = DateTime.now();
        list.sort((a, b) => (b.sortTime ?? now).compareTo(a.sortTime ?? now));
        return list;
      });

  /// Newest first (the chat list is displayed reversed).
  Stream<List<ChatMessage>> watchMessages(String chatId) => _chats
      .doc(chatId)
      .collection('messages')
      .orderBy('createdAt', descending: true)
      .limit(100)
      .snapshots()
      .map((s) => s.docs.map(ChatMessage.fromDoc).toList());

  Future<void> send(String chatId, String senderId, String text) {
    final chat = _chats.doc(chatId);
    final msg = chat.collection('messages').doc();
    final batch = _db.batch()
      ..set(msg, {
        'senderId': senderId,
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
      })
      ..update(chat, {
        'lastMessage': text,
        'lastSenderId': senderId,
        'lastMessageAt': FieldValue.serverTimestamp(),
      });
    return batch.commit();
  }
}
