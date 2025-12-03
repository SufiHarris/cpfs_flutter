import 'package:flutter/material.dart';
import '../widgets/app_scaffold.dart';

class CollaborationScreen extends StatelessWidget {
  const CollaborationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3CD),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFFEEBA)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                offset: const Offset(0, 2),
                blurRadius: 4,
              ),
            ],
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'VETERAN COLLABORATION',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF856404),
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Status: In Work',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF856404),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
