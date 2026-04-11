import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../controllers/tournament_form_controller.dart';
import '../widgets/step_card.dart';
import '../widgets/form_fields.dart';
import '../widgets/form_helpers.dart';
import '../widgets/tournament_selectors.dart';

/// Paso 6 — Staff y Soporte: Gestión de administradores y datos de contacto.
class Step6Staff extends StatelessWidget {
  const Step6Staff({
    super.key,
    required this.adminController,
    required this.adminError,
    required this.isAddingAdmin,
    required this.extraAdmins,
    required this.onAdminChanged,
    required this.onAddAdmin,
    required this.onRemoveAdmin,
    required this.contactEmailController,
    required this.contactEmailError,
    required this.onContactEmailChanged,
    required this.contactPhoneController,
    required this.onContactPhoneChanged,
    required this.contactLinkControllers,
    required this.onAddContactLink,
    required this.onRemoveContactLink,
  });

  // Admins
  final TextEditingController adminController;
  final String? adminError;
  final bool isAddingAdmin;
  final List<FormAdminEntry> extraAdmins;
  final ValueChanged<String>? onAdminChanged;
  final VoidCallback onAddAdmin;
  final ValueChanged<String> onRemoveAdmin;

  // Contacto
  final TextEditingController contactEmailController;
  final String? contactEmailError;
  final ValueChanged<String>? onContactEmailChanged;

  final TextEditingController contactPhoneController;
  final ValueChanged<String>? onContactPhoneChanged;

  final List<TextEditingController> contactLinkControllers;
  final VoidCallback onAddContactLink;
  final ValueChanged<int> onRemoveContactLink;

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final showCreatorChip = currentUid != null;

    return StepCard(
      icon: Icons.support_agent_rounded,
      title: 'Staff y Soporte',
      subtitle:
          'Gestiona tu equipo de administradores y facilita datos de contacto para los participantes.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Administradores ──────────────────────────────────
          _buildSectionHeader(
            icon: Icons.admin_panel_settings_outlined,
            title: 'Administradores',
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
                const AdminChip(label: 'Tú (creador)', isFixed: true),
              ...extraAdmins.map(
                (admin) => AdminChip(
                  label: admin.label,
                  isFixed: false,
                  onRemove: () => onRemoveAdmin(admin.uid),
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),
          const GlassDivider(),
          const SizedBox(height: 20),

          // ── Contacto ─────────────────────────────────────────
          _buildSectionHeader(
            icon: Icons.contact_mail_outlined,
            title: 'Datos de contacto',
          ),
          const SizedBox(height: 8),
          Text(
            'Facilita al menos un email para que los participantes puedan contactar.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 12.5,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 14),

          GlassField(
            controller: contactEmailController,
            hint: 'email@ejemplo.com',
            icon: Icons.email_outlined,
            label: 'Email de contacto *',
            errorText: contactEmailError,
            keyboardType: TextInputType.emailAddress,
            onChanged: onContactEmailChanged,
          ),
          const SizedBox(height: 14),
          GlassField(
            controller: contactPhoneController,
            hint: '+34 600 123 456',
            icon: Icons.phone_outlined,
            label: 'Teléfono (opcional)',
            keyboardType: TextInputType.phone,
            onChanged: onContactPhoneChanged,
          ),
          const SizedBox(height: 18),

          // ── Enlaces opcionales ──
          const FieldLabel(label: 'Enlaces (opcional)'),
          const SizedBox(height: 4),
          Text(
            'Web, redes sociales, grupo de WhatsApp...',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          ...List.generate(contactLinkControllers.length, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    child: GlassField(
                      controller: contactLinkControllers[i],
                      hint: 'https://...',
                      icon: Icons.link_rounded,
                      label: 'Enlace ${i + 1}',
                      keyboardType: TextInputType.url,
                    ),
                  ),
                  if (contactLinkControllers.length > 1) ...[
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => onRemoveContactLink(i),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: const Color(0xFFFF4D6A).withValues(alpha: 0.1),
                          border: Border.all(
                            color:
                                const Color(0xFFFF4D6A).withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Icon(Icons.close_rounded,
                            color: Color(0xFFFF4D6A), size: 18),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
          const SizedBox(height: 4),
          InkWell(
            onTap: onAddContactLink,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.white.withValues(alpha: 0.04),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_rounded,
                      color: Colors.white.withValues(alpha: 0.6), size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Añadir enlace',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
      {required IconData icon, required String title}) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF00D4FF), size: 18),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
