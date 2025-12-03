import 'package:flutter/material.dart';
import 'bottom_nav.dart';
import 'top_nav.dart';

class AppScaffold extends StatelessWidget {
  final Widget child;

  const AppScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TopNavBar(),
      body: child,
      bottomNavigationBar: const BottomNavBar(),
    );
  }
}
