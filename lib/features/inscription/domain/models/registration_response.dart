import 'registration_field.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  RegistrationResponse  ·  Dominio
//
//  Respuesta de un usuario a un campo adicional del formulario de inscripción.
//  Se almacena como parte de la inscripción (participante):
//    tournaments/{tournamentId}/participants/{participantId}.responses
//
//  Guarda un snapshot mínimo del campo para que, si el organizador cambia
//  el formulario después, la inscripción antigua siga siendo legible.
// ─────────────────────────────────────────────────────────────────────────────

class RegistrationResponse {
  const RegistrationResponse({
    required this.fieldId,
    required this.fieldLabelSnapshot,
    required this.fieldType,
    required this.value,
  });

  /// ID del campo al que responde.
  final String fieldId;

  /// Snapshot del label del campo en el momento de la inscripción.
  final String fieldLabelSnapshot;

  /// Tipo del campo (para renderizado futuro sin schema).
  final RegistrationFieldType fieldType;

  /// Valor introducido por el usuario.
  /// - String para text/textarea/number/date/select
  /// - bool para checkbox
  /// - List<String> para multiSelect
  final dynamic value;

  /// Crea una respuesta a partir de un campo y un valor.
  factory RegistrationResponse.fromField(RegistrationField field, dynamic value) {
    return RegistrationResponse(
      fieldId: field.id,
      fieldLabelSnapshot: field.label,
      fieldType: field.type,
      value: value,
    );
  }

  // ── Serialización ──────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
        'fieldId': fieldId,
        'fieldLabelSnapshot': fieldLabelSnapshot,
        'fieldType': fieldType.name,
        'value': value,
      };

  factory RegistrationResponse.fromMap(Map<String, dynamic> map) {
    return RegistrationResponse(
      fieldId: map['fieldId'] as String? ?? '',
      fieldLabelSnapshot: map['fieldLabelSnapshot'] as String? ?? '',
      fieldType: RegistrationFieldType.fromValue(
        map['fieldType'] as String? ?? '',
      ),
      value: map['value'],
    );
  }

  RegistrationResponse copyWith({
    String? fieldId,
    String? fieldLabelSnapshot,
    RegistrationFieldType? fieldType,
    dynamic value,
  }) {
    return RegistrationResponse(
      fieldId: fieldId ?? this.fieldId,
      fieldLabelSnapshot: fieldLabelSnapshot ?? this.fieldLabelSnapshot,
      fieldType: fieldType ?? this.fieldType,
      value: value ?? this.value,
    );
  }
}
