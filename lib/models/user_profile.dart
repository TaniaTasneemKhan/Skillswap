import 'package:cloud_firestore/cloud_firestore.dart';

import 'availability.dart';

class UserProfile {
  final String uid;
  final String name;
  final String email;
  final String bio;
  final String photoUrl;
  final List<String> skillsOffered;
  final List<String> skillsWanted;
  final bool profileComplete;
  final List<AvailabilitySlot> availability; // saved separately via UserService

  const UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    this.bio = '',
    this.photoUrl = '',
    this.skillsOffered = const [],
    this.skillsWanted = const [],
    this.profileComplete = false,
    this.availability = const [],
  });

  factory UserProfile.fromMap(String uid, Map<String, dynamic> m) => UserProfile(
        uid: uid,
        name: m['name'] ?? '',
        email: m['email'] ?? '',
        bio: m['bio'] ?? '',
        photoUrl: m['photoUrl'] ?? '',
        skillsOffered: List<String>.from(m['skillsOffered'] ?? const []),
        skillsWanted: List<String>.from(m['skillsWanted'] ?? const []),
        profileComplete: m['profileComplete'] ?? false,
        availability: ((m['availability'] as List?) ?? const [])
            .map((e) => AvailabilitySlot.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'bio': bio,
        'photoUrl': photoUrl,
        'skillsOffered': skillsOffered,
        'skillsWanted': skillsWanted,
        'profileComplete': profileComplete,
        'updatedAt': FieldValue.serverTimestamp(),
      };
}
