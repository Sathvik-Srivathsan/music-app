import 'package:flutter/material.dart';
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

class _MusicCollectionAppState extends State<MusicCollectionApp> {
  // Created eagerly (not lazily via Provider) so the auth gate is active from
  // the very first frame and can be handed to the router's redirect.
  final AuthProvider _auth = AuthProvider();

  @override
  void dispose() {
    _auth.dispose();
    super.dispose();
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