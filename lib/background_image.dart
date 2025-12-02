import 'package:flutter/material.dart';

class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background image
        Positioned.fill(
          child: Opacity(
            opacity: 0.50, // 🔥 Adjust this for lighter/darker effect
            child: Image.asset(
              'assets/namibiacrusade.jpeg', // Change to your image path
              fit: BoxFit.cover,
            ),
          ),
        ),

        // Foreground UI
        Positioned.fill(
          child: child,
        ),
      ],
    );
  }
}
