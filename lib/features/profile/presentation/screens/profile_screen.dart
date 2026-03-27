import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TourneyApp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const ProfileScreen(),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ShaderMask(
            shaderCallback: (b) => const LinearGradient(
              colors: [Color(0xFF6C63FF), Color(0xFF00D4FF)],
            ).createShader(b),
            child: const Icon(Icons.person_rounded, size: 64, color: Colors.white),
          ),
          const SizedBox(height: 16),
          ShaderMask(
            shaderCallback: (b) => const LinearGradient(
              colors: [Color(0xFFFFFFFF), Color(0xFFB0A8FF)],
            ).createShader(b),
            child: const Text(
              'Perfil',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pantalla en construcción',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.35),
            ),
          ),
        ],
      ),
    );
  }
}
