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
