import 'package:cloud_firestore/cloud_firestore.dart';

import 'registration_field.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  RegistrationFormSchema  ·  Dominio
//
//  Esquema versionado del formulario de inscripción de un torneo.
//  Se almacena dentro del documento del torneo:
//    tournaments/{tournamentId}.registrationForm
//
//  El versionado evita que cambios futuros en el formulario rompan
//  inscripciones ya creadas. Cada inscripción guarda la versión del
//  esquema con la que fue rellenada.
// ─────────────────────────────────────────────────────────────────────────────

class RegistrationFormSchema {
  const RegistrationFormSchema({
    required this.version,
    required this.fields,
    this.createdAt,
    this.updatedAt,
  });

  /// Versión del formulario. Se auto-incrementa al guardar cambios.
  final int version;

  /// Lista de campos adicionales definidos por el organizador.
  final List<RegistrationField> fields;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Devuelve solo los campos activos, ordenados por `order`.
  List<RegistrationField> get activeFields {
    final active = fields.where((f) => f.enabled).toList();
    active.sort((a, b) => a.order.compareTo(b.order));
    return active;
  }

  /// Indica si el formulario tiene campos activos.
  bool get hasActiveFields => activeFields.isNotEmpty;

  /// Valida toda la configuración del formulario.
  /// Devuelve la lista de errores encontrados (vacía si todo es válido).
  List<String> validateConfiguration() {
    final errors = <String>[];
    for (final field in fields) {
      final error = field.validateConfiguration();
      if (error != null) {
        errors.add('Campo "${field.label}": $error');
      }
    }
    return errors;
  }

  // ── Serialización ──────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
        'version': version,
        'fields': fields.map((f) => f.toMap()).toList(),
        'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
        'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      };

  factory RegistrationFormSchema.fromMap(Map<String, dynamic> map) {
    return RegistrationFormSchema(
      version: (map['version'] as num?)?.toInt() ?? 1,
      fields: (map['fields'] as List<dynamic>? ?? const <dynamic>[])
          .map((e) => RegistrationField.fromMap(e as Map<String, dynamic>))
          .toList(),
      createdAt: _nullableDate(map['createdAt']),
      updatedAt: _nullableDate(map['updatedAt']),
    );
  }

  RegistrationFormSchema copyWith({
    int? version,
    List<RegistrationField>? fields,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RegistrationFormSchema(
      version: version ?? this.version,
      fields: fields ?? this.fields,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Crea un schema vacío (sin campos).
  factory RegistrationFormSchema.empty() {
    return const RegistrationFormSchema(version: 1, fields: []);
  }

  static DateTime? _nullableDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
