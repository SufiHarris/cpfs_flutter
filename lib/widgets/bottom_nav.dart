import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/app_auth_provider.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final authProvider = Provider.of<AppAuthProvider>(context);
    final isAuthenticating = location == '/auth';

    return Container(
      height: 90,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(0, -2),
            blurRadius: 3,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(
            context,
            icon: Icons.home,
            label: 'Home',
            path: '/',
            isActive: location == '/' && !isAuthenticating,
          ),
          _buildNavItem(
            context,
            icon: Icons.favorite,
            label: 'Program\nServices',
            path: '/protected/charity',
            isActive: location.contains('/protected/charity'),
            flex: 1.2,
            fontSize: 11,
            requiresAuth: true,
          ),
          _buildNavItem(
            context,
            icon: Icons.shopping_cart,
            label: 'CPFS\nServices',
            path: '/protected/retail',
            isActive: location.contains('/protected/retail'),
            flex: 1.2,
            fontSize: 11,
            requiresAuth: true,
          ),
          if (authProvider.isAuthenticated)
            _buildNavItem(
              context,
              icon: Icons.person,
              label: 'Profile',
              path: '/protected/profile',
              isActive: location.contains('/protected/profile'),
            )
          else
            _buildNavItem(
              context,
              icon: Icons.login,
              label: 'Sign In',
              path: '/auth',
              isActive: isAuthenticating,
            ),
          _buildNavItem(
            context,
            icon: Icons.menu,
            label: 'Menu',
            path: '/menu',
            isActive: location == '/menu',
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String path,
    required bool isActive,
    double flex = 1.0,
    double fontSize = 12,
    bool requiresAuth = false,
  }) {
    final authProvider = Provider.of<AppAuthProvider>(context, listen: false);

    return Expanded(
      flex: (flex * 10).toInt(),
      child: GestureDetector(
        onTap: () {
          if (requiresAuth && !authProvider.isAuthenticated) {
            context.go('/auth');
          } else {
            context.go(path);
          }
        },
        child: Container(
          decoration: BoxDecoration(
            border: isActive
                ? const Border(
                    top: BorderSide(color: Color(0xFF3498DB), width: 3),
                  )
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 24,
                color: isActive
                    ? const Color(0xFF3498DB)
                    : const Color(0xFF13345C),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: fontSize,
                  color: isActive
                      ? const Color(0xFF3498DB)
                      : const Color(0xFF13345C),
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
