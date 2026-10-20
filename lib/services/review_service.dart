import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/review.dart';
import '../models/session.dart';

class AlreadyReviewedException implements Exception {
  const AlreadyReviewedException();
}

class ReviewService {
  final FirebaseFirestore _db;
  ReviewService(this._db);

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('reviews');

  /// Reviews written about [uid], newest first.
  Stream<List<Review>> watchFor(String uid) =>
      _col.where('revieweeId', isEqualTo: uid).snapshots().map((s) {
        final list = s.docs.map(Review.fromDoc).toList();
        final now = DateTime.now();
        list.sort((a, b) => (b.createdAt ?? now).compareTo(a.createdAt ?? now));
        return list;
      });

  /// Ids of sessions that [uid] has already reviewed.
  Stream<Set<String>> watchGivenSessionIds(String uid) =>
      _col.where('reviewerId', isEqualTo: uid).snapshots().map(
          (s) => s.docs.map((d) => (d.data()['sessionId'] ?? '') as String).toSet());

  /// Saves the review and updates the partner's reputation totals in ONE
  /// transaction. Firestore rules verify that the totals only grow by exactly
  /// this review's rating, so ratings cannot be faked.
  Future<void> submit({
    required Session session,
    required String reviewerId,
    required String reviewerName,
    required String reviewerPhotoUrl,
    required int rating,
    required String comment,
  }) async {
    assert(rating >= 1 && rating <= 5);
    final revieweeId = session.partnerId(reviewerId);
    final reviewRef = _col.doc('${session.id}_$reviewerId');
    final userRef = _db.collection('users').doc(revieweeId);

    await _db.runTransaction((tx) async {
      final existing = await tx.get(reviewRef);
      if (existing.exists) throw const AlreadyReviewedException();
      final userSnap = await tx.get(userRef);
      final data = userSnap.data() ?? <String, dynamic>{};
      final count = (data['ratingCount'] as num?)?.toInt() ?? 0;
      final sum = (data['ratingSum'] as num?)?.toInt() ?? 0;

      tx.set(reviewRef, {
        'sessionId': session.id,
        'topic': session.topic,
        'reviewerId': reviewerId,
        'reviewerName': reviewerName,
        'reviewerPhotoUrl': reviewerPhotoUrl,
        'revieweeId': revieweeId,
        'rating': rating,
        'comment': comment,
        'createdAt': FieldValue.serverTimestamp(),
      });
      tx.update(userRef, {
        'ratingCount': count + 1,
        'ratingSum': sum + rating,
        'lastReviewId': reviewRef.id,
      });
    });
  }
}
