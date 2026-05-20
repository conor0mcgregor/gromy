import 'package:cloud_firestore/cloud_firestore.dart';

enum RegistrationFieldType {
  text,
  textarea,
  number,
  date,
  checkbox,
  select,
  multiSelect;

  static RegistrationFieldType? maybeFromValue(String value) {
    for (final type in RegistrationFieldType.values) {
      if (type.name == value) return type;
    }
    return null;
  }

  static RegistrationFieldType fromValue(String value) {
    return maybeFromValue(value) ?? RegistrationFieldType.text;
  }
}

extension RegistrationFieldTypeLabel on RegistrationFieldType {
  String get label {
    return switch (this) {
      RegistrationFieldType.text => 'Texto corto',
      RegistrationFieldType.textarea => 'Texto largo',
      RegistrationFieldType.number => 'Numero',
      RegistrationFieldType.date => 'Fecha',
      RegistrationFieldType.checkbox => 'Checkbox',
      RegistrationFieldType.select => 'Seleccion unica',
      RegistrationFieldType.multiSelect => 'Seleccion multiple',
    };
  }

  bool get usesOptions =>
      this == RegistrationFieldType.select ||
      this == RegistrationFieldType.multiSelect;
}

class RegistrationField {
  const RegistrationField({
    required this.id,
    required this.label,
    required this.type,
    required this.required,
    required this.order,
    required this.enabled,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.options = const [],
  });

  final String id;
  final String label;
  final String? description;
  final RegistrationFieldType type;
  final bool required;
  final List<String> options;
  final int order;
  final bool enabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'description': description,
      'type': type.name,
      'required': required,
      'options': options,
      'order': order,
      'enabled': enabled,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory RegistrationField.fromMap(Map<String, dynamic> map) {
    return RegistrationField(
      id: map['id'] as String? ?? '',
      label: map['label'] as String? ?? '',
      description: map['description'] as String?,
      type: RegistrationFieldType.fromValue(map['type'] as String? ?? ''),
      required: map['required'] as bool? ?? false,
      options: (map['options'] as List<dynamic>? ?? const <dynamic>[])
          .map((value) => value.toString())
          .toList(),
      order: (map['order'] as num?)?.toInt() ?? 0,
      enabled: map['enabled'] as bool? ?? true,
      createdAt: _dateFromValue(map['createdAt']),
      updatedAt: _dateFromValue(map['updatedAt']),
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
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static DateTime _dateFromValue(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}

class RegistrationFormSchema {
  const RegistrationFormSchema({this.version = 1, this.fields = const []});

  final int version;
  final List<RegistrationField> fields;

  List<RegistrationField> get activeFields {
    final active = fields.where((field) => field.enabled).toList();
    active.sort((a, b) => a.order.compareTo(b.order));
    return active;
  }

  bool get hasActiveFields => activeFields.isNotEmpty;

  Map<String, dynamic> toMap() {
    return {
      'version': version,
      'fields': fields.map((field) => field.toMap()).toList(),
    };
  }

  factory RegistrationFormSchema.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const RegistrationFormSchema();
    final fields = (map['fields'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(RegistrationField.fromMap)
        .toList();
    return RegistrationFormSchema(
      version: (map['version'] as num?)?.toInt() ?? 1,
      fields: fields,
    );
  }

  RegistrationFormSchema copyWith({
    int? version,
    List<RegistrationField>? fields,
  }) {
    return RegistrationFormSchema(
      version: version ?? this.version,
      fields: fields ?? this.fields,
    );
  }
}

class RegistrationResponse {
  const RegistrationResponse({
    required this.fieldId,
    required this.fieldLabelSnapshot,
    required this.fieldType,
    required this.value,
  });

  final String fieldId;
  final String fieldLabelSnapshot;
  final RegistrationFieldType fieldType;
  final dynamic value;

  Map<String, dynamic> toMap() {
    return {
      'fieldId': fieldId,
      'fieldLabelSnapshot': fieldLabelSnapshot,
      'fieldType': fieldType.name,
      'value': value,
    };
  }

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
}

class RegistrationFormValidator {
  static const int maxLabelLength = 80;
  static const int maxDescriptionLength = 240;
  static const int maxOptions = 20;

  static List<String> validateSchema(RegistrationFormSchema schema) {
    final errors = <String>[];
    final labels = <String>{};

    for (final field in schema.fields) {
      final label = field.label.trim();
      if (label.isEmpty) {
        errors.add('Hay un campo adicional sin titulo.');
      }
      if (label.length > maxLabelLength) {
        errors.add('El titulo "$label" es demasiado largo.');
      }
      final description = field.description?.trim();
      if (description != null && description.length > maxDescriptionLength) {
        errors.add('La descripcion de "$label" es demasiado larga.');
      }
      if (!labels.add(label.toLowerCase())) {
        errors.add('Hay campos adicionales con el mismo titulo.');
      }
      if (field.type.usesOptions) {
        final cleanOptions = field.options
            .map((option) => option.trim())
            .where((option) => option.isNotEmpty)
            .toList();
        if (cleanOptions.isEmpty) {
          errors.add('El campo "$label" necesita opciones.');
        }
        if (cleanOptions.length > maxOptions) {
          errors.add('El campo "$label" tiene demasiadas opciones.');
        }
      }
      final sensitiveWords = [
        'dni',
        'password',
        'contrasena',
        'tarjeta',
        'cuenta bancaria',
        'iban',
      ];
      final lowerLabel = label.toLowerCase();
      if (sensitiveWords.any(lowerLabel.contains)) {
        errors.add('Evita pedir datos sensibles en "$label".');
      }
    }

    return errors;
  }

  static Map<String, String> validateResponses({
    required RegistrationFormSchema schema,
    required Map<String, dynamic> values,
  }) {
    final errors = <String, String>{};
    for (final field in schema.activeFields) {
      final value = values[field.id];
      if (field.required && _isEmpty(field, value)) {
        errors[field.id] = field.type == RegistrationFieldType.checkbox
            ? 'Debes marcar este campo.'
            : 'Este campo es obligatorio.';
        continue;
      }
      if (_isEmpty(field, value)) continue;

      switch (field.type) {
        case RegistrationFieldType.number:
          if (num.tryParse(value.toString()) == null) {
            errors[field.id] = 'Introduce un numero valido.';
          }
          break;
        case RegistrationFieldType.date:
          if (DateTime.tryParse(value.toString()) == null) {
            errors[field.id] = 'Introduce una fecha valida.';
          }
          break;
        case RegistrationFieldType.select:
          if (!field.options.contains(value.toString())) {
            errors[field.id] = 'Selecciona una opcion valida.';
          }
          break;
        case RegistrationFieldType.multiSelect:
          final selected = value is List
              ? value.map((item) => item.toString()).toList()
              : <String>[];
          if (selected.any((item) => !field.options.contains(item))) {
            errors[field.id] = 'Selecciona opciones validas.';
          }
          break;
        case RegistrationFieldType.text:
        case RegistrationFieldType.textarea:
        case RegistrationFieldType.checkbox:
          break;
      }
    }
    return errors;
  }

  static List<RegistrationResponse> buildResponses({
    required RegistrationFormSchema schema,
    required Map<String, dynamic> values,
  }) {
    return schema.activeFields.map((field) {
      return RegistrationResponse(
        fieldId: field.id,
        fieldLabelSnapshot: field.label,
        fieldType: field.type,
        value: values[field.id],
      );
    }).toList();
  }

  static bool _isEmpty(RegistrationField field, dynamic value) {
    return switch (field.type) {
      RegistrationFieldType.checkbox => value != true,
      RegistrationFieldType.multiSelect => value is! List || value.isEmpty,
      _ => value == null || value.toString().trim().isEmpty,
    };
  }
}
