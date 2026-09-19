import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:music_collection/core/auth/auth_provider.dart';
import 'package:music_collection/core/auth/login_screen.dart';
import 'package:music_collection/features/insert/presentation/screens/insert_screen.dart';
import 'package:music_collection/features/search/presentation/screens/search_screen.dart';
import 'package:music_collection/features/database/presentation/screens/database_screen.dart';
import 'package:music_collection/features/manage/presentation/screens/manage_screen.dart';
import 'package:music_collection/features/statistics/presentation/screens/statistics_screen.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  /// Public accessor for the root navigator so the app-level back-button
  /// interceptor can pop any open root-navigator modal/dialog.
  static GlobalKey<NavigatorState> get rootNavigatorKey => _rootNavigatorKey;

  static GoRouter router(AuthProvider auth) => GoRouter(
        // Re-evaluate the guard whenever auth state changes (signed in, signed
        // out, or an "Access denied" rejection arrives).
        refreshListenable: auth,
        initialLocation: '/login',
        navigatorKey: _rootNavigatorKey,
        // Unfocus on every pop so a dialog/screen that is closed does not
        // re-prime focus (and the software keyboard) on a background
        // Offstage tab field.
        observers: [_UnfocusOnPopObserver()],
        redirect: (context, state) {
          final status = auth.status;
          final location = state.matchedLocation;
          final isLogin = location == '/login';

          if (status == AuthStatus.authenticated) {
            // Signed in: never land on /login; go to the default tab.
            return isLogin ? '/insert' : null;
          }
          // Not authenticated (loading / unauthenticated / denied): only the
          // login screen is reachable. "denied" keeps the user on /login with
          // the "Access denied" message so they can retry.
          return isLogin ? null : '/login';
        },
        routes: [
          GoRoute(
            path: '/login',
            builder: (context, state) => const LoginScreen(),
          ),
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

/// Clears the primary focus whenever any route is popped (dialog, screen,
/// etc.). The shell keeps every visited tab alive via Offstage, so their text
/// fields remain focusable; without clearing focus the software keyboard
/// would pop back up right after a modal is closed.
class _UnfocusOnPopObserver extends NavigatorObserver {
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    // Post-frame so the pop completes before focus is cleared; prevents the
    // keyboard from re-opening on an Offstage tab field.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.focusManager.primaryFocus?.unfocus();
    });
  }
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
