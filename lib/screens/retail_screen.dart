import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/app_scaffold.dart';

class RetailScreen extends StatelessWidget {
  const RetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final services = [
      {'id': '1', 'name': 'Request A Phone', 'icon': Icons.phone_iphone},
      {'id': '2', 'name': 'Minutes that Matter', 'icon': Icons.access_time},
      {'id': '3', 'name': 'Helping Heroes Home', 'icon': Icons.home},
      {'id': '4', 'name': 'Evergreen Program', 'icon': Icons.eco},
      {'id': '5', 'name': 'Submit Phone Donation', 'icon': Icons.card_giftcard},
    ];

    return AppScaffold(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'CPFS Services',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF13345C),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Cell Phones For Soldiers provides various services to support military members, veterans, and their families',
            style: TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ...services.map((service) => _buildServiceCard(context, service)),
        ],
      ),
    );
  }

  Widget _buildServiceCard(BuildContext context, Map<String, dynamic> service) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(20),
        leading: Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: const Color(0xFFF0F8FF),
            borderRadius: BorderRadius.circular(35),
          ),
          child: Icon(
            service['icon'] as IconData,
            color: const Color(0xFF3498DB),
            size: 40,
          ),
        ),
        title: Text(
          service['name'] as String,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF13345C),
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Color(0xFF13345C)),
        onTap: () => context.go('/protected/retail/${service['id']}'),
      ),
    );
  }
}
