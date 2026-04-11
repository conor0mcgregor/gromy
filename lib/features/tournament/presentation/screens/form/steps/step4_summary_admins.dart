import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/step_card.dart';
import '../widgets/form_fields.dart';
import '../widgets/form_helpers.dart';
import '../widgets/tournament_selectors.dart';
import '../widgets/summary_card.dart';

class FormAdminEntry {
  const FormAdminEntry({required this.uid, required this.label});
  final String uid;
  final String label;
}

class Step4SummaryAdmins extends StatelessWidget {
  const Step4SummaryAdmins({
    super.key,
    required this.name,
    required this.sport,
    required this.date,
    required this.location,
    required this.participants,
    required this.access,
    required this.adminController,
    required this.adminError,
    required this.isAddingAdmin,
    required this.extraAdmins,
    required this.onAdminChanged,
    required this.onAddAdmin,
    required this.onRemoveAdmin,
  });

  final String name;
  final String sport;
  final String date;
  final String location;
  final String participants;
  final String access;

  final TextEditingController adminController;
  final String? adminError;
  final bool isAddingAdmin;
  final List<FormAdminEntry> extraAdmins;
  final ValueChanged<String>? onAdminChanged;
  final VoidCallback onAddAdmin;
  final ValueChanged<String> onRemoveAdmin;

  @override
  Widget build(BuildContext context) {
    return StepCard(
      icon: Icons.sticky_note_2_outlined,
      title: 'Casi listo 🎉',
      subtitle: 'Revisa el resumen antes de crear el torneo.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAdminsSection(),
          const SizedBox(height: 24),

          // Resumen
          SummaryCard(
            name: name,
            sport: sport,
            date: date,
            location: location,
            participants: participants,
            access: access,
          ),
        ],
      ),
    );
  }

  Widget _buildAdminsSection() {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final showCreatorChip = currentUid != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.admin_panel_settings_outlined,
                color: Color(0xFF00D4FF), size: 18),
            const SizedBox(width: 10),
            Text(
              'Administradores',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'El creador siempre será admin. Añade otros por nickname o UID.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 12.5,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: GlassField(
                controller: adminController,
                hint: 'Nickname o UID',
                icon: Icons.person_add_alt_1_rounded,
                label: 'Añadir admin (opcional)',
                onChanged: onAdminChanged,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 48,
          child: OutlineButton(
            label: isAddingAdmin ? '...' : 'Añadir',
            icon: Icons.add_rounded,
            onPressed: isAddingAdmin ? () {} : onAddAdmin,
          ),
        ),

        if (adminError != null) ...[
          const SizedBox(height: 8),
          ErrorText(message: adminError!),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            if (showCreatorChip)
              const AdminChip(
                label: 'Tú (creador)',
                isFixed: true,
              ),
            ...extraAdmins.map(
              (admin) => AdminChip(
                label: admin.label,
                isFixed: false,
                onRemove: () => onRemoveAdmin(admin.uid),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
