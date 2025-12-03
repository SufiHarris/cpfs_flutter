import 'package:flutter/material.dart';
import '../widgets/app_scaffold.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Hero Image
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.asset(
                'assets/images/bridge_logo.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(Icons.image, size: 50, color: Colors.grey),
                    ),
                  );
                },
              ),
            ),

            // Floating Card
            Transform.translate(
              offset: const Offset(0, -40),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      offset: const Offset(0, 12),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Column(
                  children: [
                    Text(
                      'Cellphones For Soldiers Marketplace',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF13345C),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'A lifeline for America\'s bravest',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Mission Section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 10,
                      child: Image.asset(
                        'assets/images/OurMission.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(color: Colors.grey[300]);
                        },
                      ),
                    ),
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.7),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 20,
                      left: 20,
                      right: 20,
                      child: Text(
                        'Connect Veterans to cost-free services, emergency funding, and publicly available resources across thousands of charity services and processes.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 15,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}
