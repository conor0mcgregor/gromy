import '../../domain/models/registration_form_schema.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  RegistrationFormRepository  ·  Contrato de dominio
//
//  Gestiona el esquema de campos adicionales de inscripción de un torneo.
//  DIP: las capas superiores dependen de esta abstracción.
// ─────────────────────────────────────────────────────────────────────────────

abstract interface class RegistrationFormRepository {
  /// Obtiene el esquema de campos adicionales del torneo.
  /// Devuelve `null` si el torneo no tiene campos configurados.
  Future<RegistrationFormSchema?> getFormSchema(String tournamentId);

  /// Guarda o actualiza el esquema de campos adicionales del torneo.
  /// Incrementa automáticamente la versión.
  Future<void> saveFormSchema(
    String tournamentId,
    RegistrationFormSchema schema,
  );

  /// Elimina el esquema de campos adicionales del torneo.
  Future<void> deleteFormSchema(String tournamentId);
}
