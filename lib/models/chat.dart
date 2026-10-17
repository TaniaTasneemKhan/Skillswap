import 'package:cloud_firestore/cloud_firestore.dart';

class ChatSummary {
  final String id;
  final List<String> participants;
  final Map<String, String> names;
  final Map<String, String> photos;
  final String lastMessage;
  final String lastSenderId;
  final DateTime? lastMessageAt;
  final DateTime? createdAt;

  const ChatSummary({
    required this.id,
    required this.participants,
    required this.names,
    required this.photos,
    this.lastMessage = '',
    this.lastSenderId = '',
    this.lastMessageAt,
    this.createdAt,
  });

  String otherId(String me) =>
      participants.firstWhere((p) => p != me, orElse: () => '');
  String otherName(String me) => names[otherId(me)] ?? 'User';
  String otherPhoto(String me) => photos[otherId(me)] ?? '';
  DateTime? get sortTime => lastMessageAt ?? createdAt;

  factory ChatSummary.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data()!;
    return ChatSummary(
      id: d.id,
      participants: List<String>.from(m['participants'] ?? const []),
      names: Map<String, String>.from(m['participantNames'] ?? const {}),
      photos: Map<String, String>.from(m['participantPhotos'] ?? const {}),
      lastMessage: m['lastMessage'] ?? '',
      lastSenderId: m['lastSenderId'] ?? '',
      lastMessageAt: (m['lastMessageAt'] as Timestamp?)?.toDate(),
      createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

class ChatMessage {
  final String id;
  final String senderId;
  final String text;
  final DateTime? createdAt; // null briefly while the server timestamp resolves

  const ChatMessage({required this.id, required this.senderId, required this.text, this.createdAt});

  factory ChatMessage.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data()!;
    return ChatMessage(
      id: d.id,
      senderId: m['senderId'] ?? '',
      text: m['text'] ?? '',
      createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
