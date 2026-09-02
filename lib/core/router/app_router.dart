import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:music_collection/features/insert/presentation/screens/insert_screen.dart';
import 'package:music_collection/features/search/presentation/screens/search_screen.dart';
import 'package:music_collection/features/database/presentation/screens/database_screen.dart';
import 'package:music_collection/features/manage/presentation/screens/manage_screen.dart';
import 'package:music_collection/features/statistics/presentation/screens/statistics_screen.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static final router = GoRouter(
    initialLocation: '/insert',
    navigatorKey: _rootNavigatorKey,
    routes: [
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        // The shell ignores the routed child and hosts its own
        // long-lived tab stack (see _ScaffoldWithNavBarState).
        builder: (context, state, child) => const ScaffoldWithNavBar(),
        routes: [
          GoRoute(
            path: '/insert',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: InsertScreen(),
            ),
          ),
          GoRoute(
            path: '/search',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SearchScreen(),
            ),
          ),
          GoRoute(
            path: '/database',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DatabaseScreen(),
            ),
          ),
          GoRoute(
            path: '/manage',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ManageScreen(),
            ),
          ),
          GoRoute(
            path: '/statistics',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: StatisticsScreen(),
            ),
          ),
        ],
      ),
    ],
  );
}

class ScaffoldWithNavBar extends StatefulWidget {
  const ScaffoldWithNavBar({super.key});

  @override
  State<ScaffoldWithNavBar> createState() => _ScaffoldWithNavBarState();
}

/// Keeps every visited tab alive offstage so screen state (form
/// text, selections, scroll positions) survives navigation. Tabs are
/// built lazily on first visit to avoid firing every screen's fetch
/// at startup.
class _ScaffoldWithNavBarState extends State<ScaffoldWithNavBar> {
  final Set<int> _visited = {0};

  static const List<Widget> _screens = [
    InsertScreen(),
    SearchScreen(),
    DatabaseScreen(),
    ManageScreen(),
    StatisticsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final current = _calculateSelectedIndex(context);
    _visited.add(current);
    return Scaffold(
      body: Stack(
        children: [
          for (var i = 0; i < _screens.length; i++)
            Offstage(
              offstage: i != current,
              child: TickerMode(
                enabled: i == current,
                child: _visited.contains(i)
                    ? _screens[i]
                    : const SizedBox.shrink(),
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF1E1E1E),
        selectedItemColor: const Color(0xFF5B9BF5),
        unselectedItemColor: const Color(0xFF9E9E9E),
        currentIndex: _calculateSelectedIndex(context),
        onTap: (index) => _onItemTapped(index, context),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            activeIcon: Icon(Icons.add_circle),
            label: 'Insert',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            activeIcon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.storage),
            activeIcon: Icon(Icons.storage),
            label: 'DB',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            activeIcon: Icon(Icons.settings),
            label: 'Manage',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Stats',
          ),
        ],
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/insert')) return 0;
    if (location.startsWith('/search')) return 1;
    if (location.startsWith('/database')) return 2;
    if (location.startsWith('/manage')) return 3;
    if (location.startsWith('/statistics')) return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/insert');
      case 1:
        context.go('/search');
      case 2:
        context.go('/database');
      case 3:
        context.go('/manage');
      case 4:
        context.go('/statistics');
    }
  }
}
