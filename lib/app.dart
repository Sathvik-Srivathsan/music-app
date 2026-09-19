import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:music_collection/core/auth/auth_provider.dart';
import 'package:music_collection/core/router/app_router.dart';
import 'package:music_collection/core/theme/app_theme.dart';
import 'package:music_collection/features/database/presentation/providers/database_provider.dart';
import 'package:music_collection/features/insert/presentation/providers/insert_provider.dart';
import 'package:music_collection/features/manage/presentation/providers/manage_provider.dart';
import 'package:music_collection/features/search/presentation/providers/search_provider.dart';
import 'package:music_collection/features/statistics/presentation/providers/statistics_provider.dart';

class MusicCollectionApp extends StatefulWidget {
  const MusicCollectionApp({super.key});

  @override
  State<MusicCollectionApp> createState() => _MusicCollectionAppState();
}

class _MusicCollectionAppState extends State<MusicCollectionApp>
    with WidgetsBindingObserver {
  // Created eagerly (not lazily via Provider) so the auth gate is active from
  // the very first frame and can be handed to the router's redirect.
  final AuthProvider _auth = AuthProvider();

  @override
  void initState() {
    super.initState();
    // Register BEFORE the router mounts so this observer runs before go_router's
    // RootBackButtonDispatcher (which crashes on back for the Offstage shell).
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _auth.dispose();
    super.dispose();
  }

  /// Handles the Android/iOS system back button before go_router's broken
  /// shell `popRoute` can run (it throws on every back press for the
  /// Offstage-based tab shell).
  ///
  ///  * if a modal/dialog is open on the root navigator, pop it;
  ///  * otherwise exit the app (standard back-at-root behaviour).
  /// On the web we defer to the framework so browser navigation keeps working.
  @override
  Future<bool> didPopRoute() async {
    WidgetsBinding.instance.focusManager.primaryFocus?.unfocus();
    final root = AppRouter.rootNavigatorKey.currentState;
    if (root != null && root.canPop()) {
      root.maybePop();
      return true;
    }
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      await SystemNavigator.pop();
      return true;
    }
    return super.didPopRoute();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _auth),
        ChangeNotifierProvider(create: (_) => InsertProvider()),
        ChangeNotifierProvider(create: (_) => SearchProvider()),
        ChangeNotifierProvider(create: (_) => DatabaseProvider()),
        ChangeNotifierProvider(create: (_) => ManageProvider()),
        ChangeNotifierProvider(create: (_) => StatisticsProvider()),
      ],
      child: MaterialApp.router(
        title: 'Music Collection',
        theme: AppTheme.darkTheme,
        routerConfig: AppRouter.router(_auth),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}