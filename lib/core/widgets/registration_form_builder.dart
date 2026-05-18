import 'package:flutter/material.dart';

import '../../features/inscription/domain/models/registration_field.dart';
import '../../features/inscription/domain/models/registration_form_schema.dart';
import '../../features/inscription/domain/models/registration_response.dart';
import 'dynamic_registration_field.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  RegistrationFormBuilder  ·  Widget reutilizable
//
//  Renderiza la lista completa de campos dinámicos de un formulario.
//  Recibe el esquema y las respuestas actuales, y notifica cambios.
//  No contiene lógica de negocio.
// ─────────────────────────────────────────────────────────────────────────────

class RegistrationFormBuilder extends StatelessWidget {
  const RegistrationFormBuilder({
    super.key,
    required this.schema,
    required this.responses,
    required this.onResponseChanged,
    this.errors = const {},
    this.enabled = true,
  });

  final RegistrationFormSchema schema;

  /// Respuestas actuales indexadas por fieldId.
  final Map<String, dynamic> responses;

  /// Callback cuando cambia una respuesta.
  final void Function(String fieldId, dynamic value) onResponseChanged;

  /// Errores de validación indexados por fieldId.
  final Map<String, String> errors;

  /// Si el formulario está habilitado para edición.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final activeFields = schema.activeFields;

    if (activeFields.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título de sección
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              Icon(
                Icons.assignment_rounded,
                color: const Color(0xFF6C63FF).withValues(alpha: 0.8),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Campos adicionales',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
        // Campos
        ...activeFields.map((field) => DynamicRegistrationField(
              field: field,
              value: responses[field.id],
              onChanged: (value) => onResponseChanged(field.id, value),
              errorText: errors[field.id],
              enabled: enabled,
            )),
      ],
    );
  }

  /// Valida todas las respuestas contra el esquema.
  /// Devuelve un mapa de errores (fieldId → mensaje).
  static Map<String, String> validateAll(
    RegistrationFormSchema schema,
    Map<String, dynamic> responses,
  ) {
    final errors = <String, String>{};
    for (final field in schema.activeFields) {
      final error = field.validateValue(responses[field.id]);
      if (error != null) {
        errors[field.id] = error;
      }
    }
    return errors;
  }

  /// Convierte las respuestas a lista de [RegistrationResponse].
  static List<RegistrationResponse> toResponses(
    RegistrationFormSchema schema,
    Map<String, dynamic> responses,
  ) {
    return schema.activeFields
        .where((f) => responses.containsKey(f.id) && responses[f.id] != null)
        .map((f) => RegistrationResponse.fromField(f, responses[f.id]))
        .toList();
  }
}
