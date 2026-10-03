import 'package:flutter/material.dart';

import '../matches/matches_screen.dart';
import '../profile/profile_screen.dart';
import '../skills/browse_screen.dart';

/// Bottom-navigation shell. Modules 3-5 will add Requests/Chat tabs here.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  static const _pages = [BrowseScreen(), MatchesScreen(), ProfileScreen()];

  @override
  Widget build(BuildContext context) => Scaffold(
        body: IndexedStack(index: _index, children: _pages),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore), label: 'Browse'),
            NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'Matches'),
            NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      );
}
