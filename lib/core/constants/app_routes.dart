import 'package:cpfs_marketplace/screens/save_bookmmark_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/app_auth_provider.dart';
import '../../screens/charity_detail_screen.dart';
import '../../screens/collabration_screen.dart';
import '../../screens/home_screen.dart';
import '../../screens/menu_screen.dart';
import '../../screens/auth_screen.dart';
import '../../screens/profile_screen.dart';
import '../../screens/charity_screen.dart';
import '../../screens/retail_screen.dart';
import '../../screens/retail_detail_screen.dart';
import '../../screens/service_map_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/menu',
        builder: (context, state) => const MenuScreen(),
      ),
      GoRoute(
        path: '/protected/charity/details/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return CharityDetailsScreen(charityId: id);
        },
        redirect: (context, state) => _authGuard(context),
      ),
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/protected/profile',
        builder: (context, state) => const ProfileScreen(),
        redirect: (context, state) => _authGuard(context),
      ),
      GoRoute(
        path: '/protected/charity',
        builder: (context, state) => const CharityScreen(),
        redirect: (context, state) => _authGuard(context),
      ),
      GoRoute(
        path: '/protected/retail',
        builder: (context, state) => const RetailScreen(),
        redirect: (context, state) => _authGuard(context),
      ),
      GoRoute(
        path: '/protected/retail/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return RetailDetailScreen(id: id);
        },
        redirect: (context, state) => _authGuard(context),
      ),
      GoRoute(
        path: '/protected/collaboration',
        builder: (context, state) => const CollaborationScreen(),
        redirect: (context, state) => _authGuard(context),
      ),
      GoRoute(
        path: '/protected/services-map',
        builder: (context, state) => const MapsScreen(),
        redirect: (context, state) => _authGuard(context),
      ),
      GoRoute(
        path: '/protected/saved',
        builder: (context, state) => const SavedBookmarksScreen(),
        redirect: (context, state) => _authGuard(context),
      ),
    ],
  );

  static String? _authGuard(BuildContext context) {
    final authProvider = Provider.of<AppAuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) {
      return '/auth';
    }
    return null;
  }
}
