import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/app_scaffold.dart';

class RetailDetailScreen extends StatelessWidget {
  final String id;

  const RetailDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Service Detail #$id',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF13345C),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Service information will be displayed here.',
              style: TextStyle(fontSize: 16),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3498DB),
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Back to Services',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
