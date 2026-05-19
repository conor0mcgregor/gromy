import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  RegistrationDraft  ·  Dominio
//
//  Representa un borrador de inscripción guardado por el usuario.
//  Se persiste en Firestore como documento de nivel raíz:
//    registrationDrafts/{userId}_{tournamentId}
//
//  El borrador NO crea ningún participante ni reserva plaza en el torneo.
//  Es únicamente datos temporales hasta que el usuario confirme la inscripción.
// ─────────────────────────────────────────────────────────────────────────────

class RegistrationDraft {
  const RegistrationDraft({
    required this.id,
    required this.userId,
    required this.tournamentId,
    required this.createdAt,
    required this.updatedAt,
    this.selectedTeamId,
    this.selectedCategoryId,
    this.additionalFieldsData = const {},
    this.status = 'draft',
  });

  /// ID del documento: "{userId}_{tournamentId}"
  final String id;

  final String userId;
  final String tournamentId;

  /// Equipo seleccionado (si el torneo es por equipos).
  final String? selectedTeamId;

  /// Categoría seleccionada (si el torneo tiene categorías).
  final String? selectedCategoryId;

  /// Datos adicionales para campos de registro custom (uso futuro).
  final Map<String, dynamic> additionalFieldsData;

  /// Siempre 'draft' para distinguirlo de inscripciones reales.
  final String status;

  final DateTime createdAt;
  final DateTime updatedAt;

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Devuelve true si el borrador tiene al menos un dato seleccionado.
  bool get hasData => selectedTeamId != null || selectedCategoryId != null;

  /// Genera el ID canónico para un borrador dado un userId y tournamentId.
  static String buildId(String userId, String tournamentId) =>
      '${userId}_$tournamentId';

  // ── Serialización ──────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'tournamentId': tournamentId,
        'selectedTeamId': selectedTeamId,
        'selectedCategoryId': selectedCategoryId,
        'additionalFieldsData': additionalFieldsData,
        'status': status,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  factory RegistrationDraft.fromMap(Map<String, dynamic> map) {
    return RegistrationDraft(
      id: map['id'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      tournamentId: map['tournamentId'] as String? ?? '',
      selectedTeamId: map['selectedTeamId'] as String?,
      selectedCategoryId: map['selectedCategoryId'] as String?,
      additionalFieldsData:
          (map['additionalFieldsData'] as Map<String, dynamic>?) ?? {},
      status: map['status'] as String? ?? 'draft',
      createdAt: _dateFromValue(map['createdAt']),
      updatedAt: _dateFromValue(map['updatedAt']),
    );
  }

  RegistrationDraft copyWith({
    String? selectedTeamId,
    String? selectedCategoryId,
    Map<String, dynamic>? additionalFieldsData,
    DateTime? updatedAt,
  }) {
    return RegistrationDraft(
      id: id,
      userId: userId,
      tournamentId: tournamentId,
      selectedTeamId: selectedTeamId ?? this.selectedTeamId,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      additionalFieldsData:
          additionalFieldsData ?? this.additionalFieldsData,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static DateTime _dateFromValue(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }
}
