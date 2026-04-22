import '../models/app_team.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  TeamRepository  ·  Contrato de dominio
//
//  Define las operaciones sobre la colección independiente `teams`.
//  Decisión de diseño: colección raíz (no subcolección de tournament) para
//  que un equipo pueda participar en múltiples torneos sin duplicar datos.
// ─────────────────────────────────────────────────────────────────────────────

abstract interface class TeamRepository {
  /// Crea un nuevo equipo. Si [team.id] está vacío se genera automáticamente.
  Future<AppTeam> createTeam(AppTeam team);

  /// Devuelve el equipo con [teamId], o null si no existe.
  Future<AppTeam?> getTeam(String teamId);

  /// Devuelve un stream en tiempo real con los equipos creados por [creatorId].
  Stream<List<AppTeam>> watchTeamsByCreator(String creatorId);

  /// Devuelve un stream con los equipos en los que [userId] es miembro.
  Stream<List<AppTeam>> watchTeamsByMember(String userId);

  /// Añade [userId] como miembro del equipo [teamId].
  Future<void> addMember({required String teamId, required String userId});

  /// Elimina [userId] del equipo [teamId].
  Future<void> removeMember({required String teamId, required String userId});

  /// Elimina el equipo [teamId] y todos sus datos asociados.
  Future<void> deleteTeam(String teamId);
}
