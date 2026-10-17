import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/brand_logo.dart';
import '../../utils/app_keys.dart';
import '../chat/chats_screen.dart';
import '../matches/matches_screen.dart';
import '../profile/profile_screen.dart';
import '../requests/requests_screen.dart';
import '../skills/browse_screen.dart';

/// Bottom-navigation shell. Also registers the device for push notifications
/// and routes notification taps to the right tab. Module 5 adds ratings.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});
  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;
  final _subs = <StreamSubscription<RemoteMessage>>[];

  static const _pages = [
    BrowseScreen(),
    MatchesScreen(),
    RequestsScreen(),
    ChatsScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _setupNotifications());
  }

  Future<void> _setupNotifications() async {
    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    if (uid == null) return;
    try {
      await ref.read(notificationServiceProvider).init(uid);
    } catch (_) {
      // Notifications are optional; the app works without them.
    }
    if (!mounted) return;
    _subs.add(FirebaseMessaging.onMessage.listen(_onForeground));
    _subs.add(FirebaseMessaging.onMessageOpenedApp.listen(_openFor));
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null && mounted) _openFor(initial);
  }

  void _onForeground(RemoteMessage m) {
    final n = m.notification;
    if (n == null) return;
    rootMessengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text([n.title, n.body].whereType<String>().join(': ')),
        action: SnackBarAction(label: 'View', onPressed: () => _openFor(m)),
      ));
  }

  void _openFor(RemoteMessage m) {
    final type = m.data['type'];
    setState(() => _index = type == 'message' ? 3 : 2);
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }

  static const _items = [
    (Icons.explore_outlined, Icons.explore, 'Browse'),
    (Icons.people_outline, Icons.people, 'Matches'),
    (Icons.swap_horiz, Icons.swap_horiz, 'Swaps'),
    (Icons.chat_bubble_outline, Icons.chat_bubble, 'Chats'),
    (Icons.person_outline, Icons.person, 'Profile'),
  ];

  Future<void> _logout() async {
    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    try {
      if (uid != null) await ref.read(notificationServiceProvider).removeToken(uid);
    } catch (_) {}
    await ref.read(authServiceProvider).signOut();
  }

  Widget _icon(IconData icon, int tab, int badge) => tab == 2
      ? Badge(isLabelVisible: badge > 0, label: Text('$badge'), child: Icon(icon))
      : Icon(icon);

  Widget _sidebar(int badge) => Container(
        width: 240,
        color: Colors.white,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 24, 20, 28),
                child: Align(alignment: Alignment.centerLeft, child: BrandLogo()),
              ),
              for (var i = 0; i < _items.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => setState(() => _index = i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: _index == i ? Brand.lavender : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconTheme(
                        data: IconThemeData(color: _index == i ? Brand.primary : Brand.ink, size: 22),
                        child: Row(
                          children: [
                            _icon(_index == i ? _items[i].$2 : _items[i].$1, i, badge),
                            const SizedBox(width: 14),
                            Text(
                              _items[i].$3,
                              style: TextStyle(
                                fontWeight: _index == i ? FontWeight.w700 : FontWeight.w500,
                                color: _index == i ? Brand.primary : Brand.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
                child: TextButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout),
                  label: const Text('Log out'),
                  style: TextButton.styleFrom(
                    foregroundColor: Brand.ink,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final badge = ref.watch(swapsBadgeCountProvider);
    final wide = MediaQuery.of(context).size.width >= 840;
    final body = IndexedStack(index: _index, children: _pages);

    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            _sidebar(badge),
            const VerticalDivider(width: 1),
            Expanded(child: body),
          ],
        ),
      );
    }
    return Scaffold(
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          for (var i = 0; i < _items.length; i++)
            NavigationDestination(
              icon: _icon(_items[i].$1, i, badge),
              selectedIcon: _icon(_items[i].$2, i, badge),
              label: _items[i].$3,
            ),
        ],
      ),
    );
  }
}
