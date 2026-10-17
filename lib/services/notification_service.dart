import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Registers this device for push notifications. Tokens are stored privately
/// in users/{uid}/tokens/{token}; Cloud Functions read them to send pushes.
class NotificationService {
  final FirebaseMessaging _fm;
  final FirebaseFirestore _db;
  NotificationService(this._fm, this._db);

  StreamSubscription<String>? _refreshSub;

  CollectionReference<Map<String, dynamic>> _tokens(String uid) =>
      _db.collection('users').doc(uid).collection('tokens');

  Future<void> init(String uid) async {
    final settings = await _fm.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.denied) return;
    final token = await _fm.getToken();
    if (token != null) await _save(uid, token);
    await _refreshSub?.cancel();
    _refreshSub = _fm.onTokenRefresh.listen((t) => _save(uid, t));
  }

  Future<void> _save(String uid, String token) =>
      _tokens(uid).doc(token).set({'createdAt': FieldValue.serverTimestamp()});

  /// Call before signing out so the next user on this device gets no pushes.
  Future<void> removeToken(String uid) async {
    await _refreshSub?.cancel();
    _refreshSub = null;
    final token = await _fm.getToken();
    if (token != null) await _tokens(uid).doc(token).delete();
  }
}
