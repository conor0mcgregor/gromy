import 'package:flutter/material.dart';

import '../../../auth/presentation/controllers/auth_controller.dart';
import 'package:gromy/core/widgets/glass_tab_bar.dart';
import 'profile_info_tab.dart';
import 'profile_teams_tab.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.authController,
  });

  final AuthController authController;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShaderMask(
                      shaderCallback: (b) => const LinearGradient(
                        colors: [Color(0xFFFFFFFF), Color(0xFFB0A8FF)],
                      ).createShader(b),
                      child: const Text(
                        'Perfil',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Gestiona tus datos y equipos',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.45),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const GlassTabBar(
                      tabs: [
                        GlassTab(label: 'Perfil', icon: Icons.person_rounded),
                        GlassTab(label: 'Equipos', icon: Icons.groups_rounded),
                      ],
                    )
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    ProfileInfoTab(authController: widget.authController),
                    const ProfileTeamsTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
