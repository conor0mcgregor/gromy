import 'dart:ui';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../widgets/step_card.dart';
import '../widgets/form_fields.dart';
import '../widgets/form_helpers.dart';

class Step0BasicInfo extends StatelessWidget {
  const Step0BasicInfo({
    super.key,
    required this.nameController,
    required this.descriptionController,
    required this.nameError,
    required this.descriptionError,
    required this.onNameChanged,
    required this.onDescriptionChanged,
    required this.coverBytes,
    required this.onPickCover,
    required this.onRemoveCover,
  });

  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final String? nameError;
  final String? descriptionError;
  final ValueChanged<String>? onNameChanged;
  final ValueChanged<String>? onDescriptionChanged;
  final Uint8List? coverBytes;
  final VoidCallback onPickCover;
  final VoidCallback onRemoveCover;

  @override
  Widget build(BuildContext context) {
    return StepCard(
      icon: Icons.drive_file_rename_outline_rounded,
      title: 'Nombre del torneo',
      subtitle: 'Dale una identidad a tu torneo. El nombre es lo primero que verán los participantes.',
      child: Column(
        children: [
          _buildCoverPicker(),
          const SizedBox(height: 18),
          GlassField(
            controller: nameController,
            hint: 'Ej. Liga Primavera 2026',
            icon: Icons.emoji_events_rounded,
            label: 'Nombre',
            errorText: nameError,
            capitalization: TextCapitalization.words,
            onChanged: onNameChanged,
          ),
          const SizedBox(height: 16),
          GlassField(
            controller: descriptionController,
            hint: 'Comenta brevemente en que consiste',
            icon: Icons.notes_rounded,
            label: 'Descripción',
            errorText: descriptionError,
            maxLines: 4,
            minLines: 4,
            capitalization: TextCapitalization.sentences,
            onChanged: onDescriptionChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildCoverPicker() {
    final hasImage = coverBytes != null && coverBytes!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FieldLabel(label: 'Portada'),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Material(
              color: Colors.white.withValues(alpha: 0.06),
              child: InkWell(
                onTap: onPickCover,
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (hasImage)
                        Image.memory(coverBytes!, fit: BoxFit.cover)
                      else
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF2B2B53),
                                Color(0xFF12122E),
                              ],
                            ),
                          ),
                          child: Center(),
                        ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.05),
                              Colors.black.withValues(alpha: 0.35),
                            ],
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.center,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: Colors.black.withValues(alpha: 0.35),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.12),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.photo_library_outlined,
                                  color: Colors.white, size: 18),
                              const SizedBox(width: 10),
                              Text(
                                hasImage ? 'Cambiar portada' : 'Elegir portada',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (hasImage)
                        Positioned(
                          top: 10,
                          right: 10,
                          child: InkWell(
                            onTap: onRemoveCover,
                            borderRadius: BorderRadius.circular(999),
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black.withValues(alpha: 0.35),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.14),
                                ),
                              ),
                              child: const Icon(Icons.close_rounded,
                                  color: Colors.white, size: 18),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
