import 'package:cloud_firestore/cloud_firestore.dart';

/// A rating left by one participant of a completed session for the other.
/// Document id = "<sessionId>_<reviewerId>" so each person reviews a session once.
class Review {
  final String id;
  final String sessionId;
  final String topic;
  final String reviewerId, reviewerName, reviewerPhotoUrl;
  final String revieweeId;
  final int rating; // 1..5
  final String comment;
  final DateTime? createdAt;

  const Review({
    required this.id,
    required this.sessionId,
    required this.topic,
    required this.reviewerId,
    required this.reviewerName,
    this.reviewerPhotoUrl = '',
    required this.revieweeId,
    required this.rating,
    this.comment = '',
    this.createdAt,
  });

  factory Review.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data()!;
    return Review(
      id: d.id,
      sessionId: m['sessionId'] ?? '',
      topic: m['topic'] ?? '',
      reviewerId: m['reviewerId'] ?? '',
      reviewerName: m['reviewerName'] ?? '',
      reviewerPhotoUrl: m['reviewerPhotoUrl'] ?? '',
      revieweeId: m['revieweeId'] ?? '',
      rating: (m['rating'] as num?)?.toInt() ?? 0,
      comment: m['comment'] ?? '',
      createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
