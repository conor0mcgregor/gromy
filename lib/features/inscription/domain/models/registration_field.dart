// ─────────────────────────────────────────────────────────────────────────────
//  RegistrationField  ·  Dominio
//
//  Representa un campo adicional configurado por el organizador para el
//  formulario de inscripción de un torneo.
//
//  Tipos soportados: texto, textarea, número, fecha, checkbox, selección
//  única y selección múltiple.
// ─────────────────────────────────────────────────────────────────────────────

/// Tipos de campo soportados en el formulario de inscripción.
enum RegistrationFieldType {
  text('Texto corto'),
  textarea('Texto largo'),
  number('Número'),
  date('Fecha'),
  checkbox('Casilla de verificación'),
  select('Selección única'),
  multiSelect('Selección múltiple');

  const RegistrationFieldType(this.label);
  final String label;

  /// Indica si el tipo requiere una lista de opciones.
  bool get requiresOptions =>
      this == RegistrationFieldType.select ||
      this == RegistrationFieldType.multiSelect;

  static RegistrationFieldType fromValue(String value) {
    return RegistrationFieldType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => RegistrationFieldType.text,
    );
  }
}

/// Campo adicional de inscripción configurado por el organizador.
class RegistrationField {
  const RegistrationField({
    required this.id,
    required this.label,
    required this.type,
    this.description,
    this.required = false,
    this.options = const [],
    this.order = 0,
    this.enabled = true,
    this.maxLength,
    this.createdAt,
    this.updatedAt,
  });

  /// Identificador único del campo (generado por el cliente).
  final String id;

  /// Título o pregunta del campo.
  final String label;

  /// Descripción opcional (instrucciones o aclaraciones).
  final String? description;

  /// Tipo de campo.
  final RegistrationFieldType type;

  /// Si es obligatorio rellenarlo para completar la inscripción.
  final bool required;

  /// Opciones disponibles (solo para tipos select/multiSelect).
  final List<String> options;

  /// Posición en el formulario.
  final int order;

  /// Si el campo está activo.
  final bool enabled;

  /// Longitud máxima permitida (para texto/textarea).
  final int? maxLength;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  // ── Validaciones ───────────────────────────────────────────────────────────

  /// Valida la configuración del campo (no el valor introducido por el usuario).
  /// Devuelve `null` si es válido, o un mensaje de error si no.
  String? validateConfiguration() {
    if (label.trim().isEmpty) {
      return 'El campo debe tener un título.';
    }
    if (label.length > 200) {
      return 'El título no puede superar los 200 caracteres.';
    }
    if (type.requiresOptions) {
      if (options.isEmpty) {
        return 'Debes añadir al menos una opción.';
      }
      for (final option in options) {
        if (option.trim().isEmpty) {
          return 'Las opciones no pueden estar vacías.';
        }
      }
    }
    return null;
  }

  /// Valida el valor introducido por un usuario para este campo.
  /// Devuelve `null` si es válido, o un mensaje de error si no.
  String? validateValue(dynamic value) {
    if (required) {
      if (value == null) return 'Este campo es obligatorio.';
      if (value is String && value.trim().isEmpty) {
        return 'Este campo es obligatorio.';
      }
      if (value is List && value.isEmpty) {
        return 'Selecciona al menos una opción.';
      }
      if (type == RegistrationFieldType.checkbox && value == false) {
        return 'Debes marcar esta casilla.';
      }
    }

    // Validaciones de tipo
    if (value != null && value is String && value.isNotEmpty) {
      if (type == RegistrationFieldType.number) {
        if (num.tryParse(value) == null) return 'Introduce un número válido.';
      }
      if (maxLength != null && value.length > maxLength!) {
        return 'Máximo $maxLength caracteres.';
      }
    }

    return null;
  }

  // ── Serialización ──────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
        'id': id,
        'label': label,
        'description': description,
        'type': type.name,
        'required': required,
        'options': options,
        'order': order,
        'enabled': enabled,
        'maxLength': maxLength,
      };

  factory RegistrationField.fromMap(Map<String, dynamic> map) {
    return RegistrationField(
      id: map['id'] as String? ?? '',
      label: map['label'] as String? ?? '',
      description: map['description'] as String?,
      type: RegistrationFieldType.fromValue(map['type'] as String? ?? ''),
      required: map['required'] as bool? ?? false,
      options: (map['options'] as List<dynamic>? ?? const <dynamic>[])
          .map((e) => e.toString())
          .toList(),
      order: (map['order'] as num?)?.toInt() ?? 0,
      enabled: map['enabled'] as bool? ?? true,
      maxLength: (map['maxLength'] as num?)?.toInt(),
    );
  }

  RegistrationField copyWith({
    String? id,
    String? label,
    String? description,
    RegistrationFieldType? type,
    bool? required,
    List<String>? options,
    int? order,
    bool? enabled,
    int? maxLength,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RegistrationField(
      id: id ?? this.id,
      label: label ?? this.label,
      description: description ?? this.description,
      type: type ?? this.type,
      required: required ?? this.required,
      options: options ?? this.options,
      order: order ?? this.order,
      enabled: enabled ?? this.enabled,
      maxLength: maxLength ?? this.maxLength,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
