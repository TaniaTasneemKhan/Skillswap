import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/skill_listing.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/listing_service.dart';
import '../services/user_service.dart';
import '../utils/matcher.dart';

// ---- services ----
final authServiceProvider =
    Provider((ref) => AuthService(FirebaseAuth.instance));
final userServiceProvider = Provider(
    (ref) => UserService(FirebaseFirestore.instance, FirebaseStorage.instance));
final listingServiceProvider =
    Provider((ref) => ListingService(FirebaseFirestore.instance));

// ---- auth + profile ----
final authStateProvider =
    StreamProvider<User?>((ref) => FirebaseAuth.instance.authStateChanges());

final profileProvider = StreamProvider<UserProfile?>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value(null);
  return ref.watch(userServiceProvider).watch(user.uid);
});

// ---- listings: search + filters ----
final listingsProvider = StreamProvider<List<SkillListing>>(
    (ref) => ref.watch(listingServiceProvider).watchAll());

final searchQueryProvider = StateProvider<String>((ref) => '');
final categoryFilterProvider = StateProvider<String?>((ref) => null);
final typeFilterProvider = StateProvider<String?>((ref) => null); // offer|want

final filteredListingsProvider =
    Provider.autoDispose<AsyncValue<List<SkillListing>>>((ref) {
  final q = ref.watch(searchQueryProvider).trim().toLowerCase();
  final cat = ref.watch(categoryFilterProvider);
  final type = ref.watch(typeFilterProvider);
  return ref.watch(listingsProvider).whenData((all) => all.where((l) {
        if (cat != null && l.category != cat) return false;
        if (type != null && l.type != type) return false;
        if (q.isEmpty) return true;
        return l.title.toLowerCase().contains(q) ||
            l.description.toLowerCase().contains(q) ||
            l.ownerName.toLowerCase().contains(q);
      }).toList());
});

// ---- matching ----
final otherUsersProvider = FutureProvider.autoDispose<List<UserProfile>>((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) return [];
  return ref.watch(userServiceProvider).fetchOthers(uid);
});

final matchesProvider = Provider.autoDispose<AsyncValue<List<Match>>>((ref) {
  final me = ref.watch(profileProvider).valueOrNull;
  if (me == null) return const AsyncValue.loading();
  return ref
      .watch(otherUsersProvider)
      .whenData((others) => computeMatches(me, others));
});
