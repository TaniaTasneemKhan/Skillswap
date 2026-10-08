import 'package:cloud_firestore/cloud_firestore.dart';

const kCategories = [
  'Programming', 'Design', 'Music', 'Languages',
  'Cooking', 'Fitness', 'Business', 'Other',
];
const kLevels = ['Beginner', 'Intermediate', 'Advanced'];

/// type: 'offer' (I can teach this) or 'want' (I want to learn this)
class SkillListing {
  final String id;
  final String ownerId;
  final String ownerName;
  final String ownerPhotoUrl;
  final String title;
  final String category;
  final String level;
  final String type;
  final String description;
  final DateTime? createdAt;

  const SkillListing({
    this.id = '',
    required this.ownerId,
    required this.ownerName,
    this.ownerPhotoUrl = '',
    required this.title,
    required this.category,
    required this.level,
    required this.type,
    this.description = '',
    this.createdAt,
  });

  bool get isOffer => type == 'offer';

  factory SkillListing.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data()!;
    return SkillListing(
      id: d.id,
      ownerId: m['ownerId'] ?? '',
      ownerName: m['ownerName'] ?? '',
      ownerPhotoUrl: m['ownerPhotoUrl'] ?? '',
      title: m['title'] ?? '',
      category: m['category'] ?? 'Other',
      level: m['level'] ?? 'Beginner',
      type: m['type'] ?? 'offer',
      description: m['description'] ?? '',
      createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'ownerId': ownerId,
        'ownerName': ownerName,
        'ownerPhotoUrl': ownerPhotoUrl,
        'title': title,
        'category': category,
        'level': level,
        'type': type,
        'description': description,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
