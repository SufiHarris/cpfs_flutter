import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/app_auth_provider.dart';

class TopNavBar extends StatelessWidget implements PreferredSizeWidget {
  const TopNavBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(60);

  String _getScreenTitle(String path) {
    if (path == '/') return 'Home';
    if (path == '/menu') return 'Menu';
    if (path.contains('/protected/charity')) return 'Charity Services';
    if (path.contains('/protected/retail'))
      return 'Cell Phones For Soldiers Services';
    if (path.contains('/protected/profile')) return 'Profile';
    return 'CPFS Marketplace';
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final isProfilePage = location.contains('/protected/profile');
    final authProvider = Provider.of<AppAuthProvider>(context);

    return Container(
      decoration: BoxDecoration(
        color: isProfilePage ? Colors.white : Colors.transparent,
        border: const Border(
          bottom: BorderSide(width: 0, color: Colors.transparent),
        ),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        left: 16,
        right: 16,
        bottom: 10,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo button
          GestureDetector(
            onTap: () => context.go('/'),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF3498DB), width: 1),
                image: const DecorationImage(
                  image: AssetImage('assets/images/placeholderlogo.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          // Screen Title
          Expanded(
            child: Text(
              _getScreenTitle(location),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                color: Color(0xFF13345C),
                shadows: [
                  Shadow(
                    color: Colors.white54,
                    offset: Offset(0, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
          ),

          // Profile/Sign In button
          GestureDetector(
            onTap: () {
              if (authProvider.isAuthenticated) {
                context.go('/protected/profile');
              } else {
                context.go('/auth');
              }
            },
            child: Icon(
              Icons.account_circle,
              size: 32,
              color: authProvider.isAuthenticated
                  ? const Color(0xFF3498DB)
                  : const Color(0xFF13345C),
            ),
          ),
        ],
      ),
    );
  }
}
