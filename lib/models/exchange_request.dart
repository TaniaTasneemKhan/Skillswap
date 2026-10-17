import 'package:cloud_firestore/cloud_firestore.dart';

/// A skill-exchange request from one user to another.
/// status: pending | accepted | rejected | cancelled
class ExchangeRequest {
  final String id;
  final String fromId, fromName, fromPhotoUrl;
  final String toId, toName, toPhotoUrl;
  final String skillOffered; // what the sender will teach
  final String skillWanted; // what the sender wants to learn from the receiver
  final String message;
  final String status;
  final String chatId;
  final DateTime? createdAt;

  const ExchangeRequest({
    this.id = '',
    required this.fromId,
    required this.fromName,
    this.fromPhotoUrl = '',
    required this.toId,
    required this.toName,
    this.toPhotoUrl = '',
    required this.skillOffered,
    required this.skillWanted,
    this.message = '',
    this.status = 'pending',
    this.chatId = '',
    this.createdAt,
  });

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';

  String otherId(String me) => me == fromId ? toId : fromId;
  String otherName(String me) => me == fromId ? toName : fromName;
  String otherPhoto(String me) => me == fromId ? toPhotoUrl : fromPhotoUrl;

  factory ExchangeRequest.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data()!;
    return ExchangeRequest(
      id: d.id,
      fromId: m['fromId'] ?? '',
      fromName: m['fromName'] ?? '',
      fromPhotoUrl: m['fromPhotoUrl'] ?? '',
      toId: m['toId'] ?? '',
      toName: m['toName'] ?? '',
      toPhotoUrl: m['toPhotoUrl'] ?? '',
      skillOffered: m['skillOffered'] ?? '',
      skillWanted: m['skillWanted'] ?? '',
      message: m['message'] ?? '',
      status: m['status'] ?? 'pending',
      chatId: m['chatId'] ?? '',
      createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'participants': [fromId, toId],
        'fromId': fromId,
        'fromName': fromName,
        'fromPhotoUrl': fromPhotoUrl,
        'toId': toId,
        'toName': toName,
        'toPhotoUrl': toPhotoUrl,
        'skillOffered': skillOffered,
        'skillWanted': skillWanted,
        'message': message,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      };
}
