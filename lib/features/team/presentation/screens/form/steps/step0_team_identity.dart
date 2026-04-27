import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../../../core/widgets/field_label.dart';
import '../../../../../../core/widgets/glass_text_field.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Step0 · Identidad del equipo
//
//  - Foto de perfil del equipo (circular, seleccionable)
//  - Nombre del equipo
// ─────────────────────────────────────────────────────────────────────────────

class Step0TeamIdentity extends StatelessWidget {
  const Step0TeamIdentity({
    super.key,
    required this.nameController,
    required this.nameError,
    required this.coverBytes,
    required this.onNameChanged,
    required this.onPickPhoto,
    required this.onRemovePhoto,
  });

  final TextEditingController nameController;
  final String? nameError;
  final Uint8List? coverBytes;
  final ValueChanged<String> onNameChanged;
  final VoidCallback onPickPhoto;
  final VoidCallback onRemovePhoto;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),

        // ── Título del paso ──
        _buildStepTitle(),
        const SizedBox(height: 28),

        // ── Foto de perfil ──
        Center(child: _buildPhotoSelector()),
        const SizedBox(height: 32),

        // ── Nombre del equipo ──
        const FieldLabel(label: 'Nombre del equipo'),
        const SizedBox(height: 8),
        GlassTextField(
          controller: nameController,
          hint: 'Ej: Los Invencibles',
          icon: Icons.groups_rounded,
          onChanged: onNameChanged,
        ),
        if (nameError != null) ...[
          const SizedBox(height: 8),
          _buildErrorText(nameError!),
        ],

        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildStepTitle() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF6C63FF).withValues(alpha: 0.12),
                const Color(0xFF00D4FF).withValues(alpha: 0.06),
                Colors.white.withValues(alpha: 0.02),
              ],
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF00D4FF)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
                      blurRadius: 14,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.badge_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Identidad del equipo',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Elige un nombre y una foto para tu equipo',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoSelector() {
    return GestureDetector(
      onTap: onPickPhoto,
      child: Stack(
        children: [
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: coverBytes == null
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF6C63FF).withValues(alpha: 0.3),
                        const Color(0xFF00D4FF).withValues(alpha: 0.15),
                      ],
                    )
                  : null,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6C63FF).withValues(alpha: 0.25),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipOval(
              child: coverBytes != null
                  ? Image.memory(
                      coverBytes!,
                      fit: BoxFit.cover,
                      width: 110,
                      height: 110,
                    )
                  : const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.white70,
                            size: 30,
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Foto',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
          // Botón eliminar foto
          if (coverBytes != null)
            Positioned(
              top: 0,
              right: 0,
              child: GestureDetector(
                onTap: onRemovePhoto,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFF4D6A),
                    border: Border.all(
                      color: const Color(0xFF0A0A1A),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorText(String text) {
    return Row(
      children: [
        const Icon(Icons.error_outline_rounded, color: Color(0xFFFF4D6A), size: 14),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFFFF4D6A),
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
