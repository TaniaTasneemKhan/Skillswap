import 'package:cloud_firestore/cloud_firestore.dart';

/// A learning session proposed inside a chat.
/// status: proposed | confirmed | declined | cancelled | completed
class Session {
  final String id;
  final String chatId;
  final String proposerId, proposerName, proposerPhotoUrl;
  final String inviteeId, inviteeName, inviteePhotoUrl;
  final String topic;
  final String note;
  final DateTime startAt;
  final int durationMin;
  final String status;

  const Session({
    this.id = '',
    required this.chatId,
    required this.proposerId,
    required this.proposerName,
    this.proposerPhotoUrl = '',
    required this.inviteeId,
    required this.inviteeName,
    this.inviteePhotoUrl = '',
    required this.topic,
    this.note = '',
    required this.startAt,
    required this.durationMin,
    this.status = 'proposed',
  });

  DateTime get endAt => startAt.add(Duration(minutes: durationMin));

  String partnerId(String me) => me == proposerId ? inviteeId : proposerId;
  String partnerName(String me) => me == proposerId ? inviteeName : proposerName;
  String partnerPhoto(String me) => me == proposerId ? inviteePhotoUrl : proposerPhotoUrl;

  bool overlapsRange(DateTime s, DateTime e) => startAt.isBefore(e) && s.isBefore(endAt);

  factory Session.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data()!;
    return Session(
      id: d.id,
      chatId: m['chatId'] ?? '',
      proposerId: m['proposerId'] ?? '',
      proposerName: m['proposerName'] ?? '',
      proposerPhotoUrl: m['proposerPhotoUrl'] ?? '',
      inviteeId: m['inviteeId'] ?? '',
      inviteeName: m['inviteeName'] ?? '',
      inviteePhotoUrl: m['inviteePhotoUrl'] ?? '',
      topic: m['topic'] ?? '',
      note: m['note'] ?? '',
      startAt: (m['startAt'] as Timestamp).toDate(),
      durationMin: (m['durationMin'] ?? 60) as int,
      status: m['status'] ?? 'proposed',
    );
  }

  Map<String, dynamic> toMap() => {
        'participants': [proposerId, inviteeId],
        'chatId': chatId,
        'proposerId': proposerId,
        'proposerName': proposerName,
        'proposerPhotoUrl': proposerPhotoUrl,
        'inviteeId': inviteeId,
        'inviteeName': inviteeName,
        'inviteePhotoUrl': inviteePhotoUrl,
        'topic': topic,
        'note': note,
        'startAt': Timestamp.fromDate(startAt),
        'durationMin': durationMin,
        'status': 'proposed',
        'reminderSent': false,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
