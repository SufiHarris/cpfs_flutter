import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/app_auth_provider.dart';
import '../widgets/app_scaffold.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AppAuthProvider>(context);

    return AppScaffold(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (authProvider.isAuthenticated) ...[
            _buildSection(
              context,
              items: [
                _MenuItem(
                  title: 'Veteran Public Services Map',
                  icon: Icons.map,
                  route: '/protected/services-map',
                ),
                _MenuItem(
                  title: 'Veteran Collaboration Tool',
                  icon: Icons.people,
                  route: '/protected/collaboration',
                ),
                _MenuItem(
                  title: 'Retail Services',
                  icon: Icons.shopping_cart,
                  route: '/protected/retail',
                ),
                _MenuItem(
                  title: 'CPFS Orders',
                  icon: Icons.bookmark,
                  route: '/protected/saved',
                ),
              ],
            ),
          ],
          _buildSection(
            context,
            title: 'General',
            items: [
              _MenuItem(
                title: 'Settings',
                icon: Icons.settings,
                route: '/protected/profile',
              ),
              _MenuItem(
                title: 'Help & Support',
                icon: Icons.help,
                route: '/help',
              ),
              _MenuItem(
                title: 'About Us',
                icon: Icons.info,
                route: '/about',
              ),
            ],
          ),
          if (authProvider.isAuthenticated) ...[
            const SizedBox(height: 16),
            Container(
              margin: const EdgeInsets.only(bottom: 80),
              child: ElevatedButton.icon(
                onPressed: () async {
                  await authProvider.signOut();
                  if (context.mounted) {
                    context.go('/');
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD23631),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context,
      {String? title, required List<_MenuItem> items}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF13345C),
                ),
              ),
            ),
          ...items.map((item) => _buildMenuItem(context, item)),
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, _MenuItem item) {
    return InkWell(
      onTap: () => context.go(item.route),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey[200]!, width: 1),
          ),
        ),
        child: Row(
          children: [
            Icon(item.icon, color: const Color(0xFF13345C)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                item.title,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF13345C),
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Color(0xFF13345C),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem {
  final String title;
  final IconData icon;
  final String route;

  _MenuItem({
    required this.title,
    required this.icon,
    required this.route,
  });
}
