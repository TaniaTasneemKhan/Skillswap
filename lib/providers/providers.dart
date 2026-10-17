import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/skill_listing.dart';
import '../models/chat.dart';
import '../models/exchange_request.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../services/listing_service.dart';
import '../services/request_service.dart';
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

// ---- Module 3: exchange requests ----
final requestServiceProvider =
    Provider((ref) => RequestService(FirebaseFirestore.instance));

final requestsProvider = StreamProvider<List<ExchangeRequest>>((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) return Stream.value(const []);
  return ref.watch(requestServiceProvider).watchMine(uid);
});

final incomingRequestsProvider = Provider<AsyncValue<List<ExchangeRequest>>>((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  return ref.watch(requestsProvider).whenData(
      (all) => all.where((r) => r.toId == uid).toList());
});

final sentRequestsProvider = Provider<AsyncValue<List<ExchangeRequest>>>((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  return ref.watch(requestsProvider).whenData(
      (all) => all.where((r) => r.fromId == uid).toList());
});

/// Number of pending requests waiting for my answer (tab badge).
final pendingIncomingCountProvider = Provider<int>((ref) =>
    ref.watch(incomingRequestsProvider).valueOrNull
        ?.where((r) => r.isPending)
        .length ??
    0);

// ---- Module 3: chat ----
final chatServiceProvider =
    Provider((ref) => ChatService(FirebaseFirestore.instance));

final chatsProvider = StreamProvider<List<ChatSummary>>((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) return Stream.value(const []);
  return ref.watch(chatServiceProvider).watchMine(uid);
});

final messagesProvider = StreamProvider.autoDispose
    .family<List<ChatMessage>, String>(
        (ref, chatId) => ref.watch(chatServiceProvider).watchMessages(chatId));
