import '../../../tournament/data/model/app_tournament.dart';
import '../../data/models/app_invitation.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  InvitationValidationResult  ·  Resultado sellado de validación
//
//  Usa sealed class + pattern matching para que los controllers y la UI traten
//  todos los casos de forma exhaustiva y sin exponer errores crudos.
// ─────────────────────────────────────────────────────────────────────────────

sealed class InvitationValidationResult {
  const InvitationValidationResult();
}

/// La invitación es válida: se dispone del torneo y del documento de invitación.
final class InvitationValid extends InvitationValidationResult {
  const InvitationValid({
    required this.invitation,
    required this.tournament,
  });

  final AppInvitation invitation;
  final AppTournament tournament;
}

/// El token no existe en la base de datos.
final class InvitationNotFound extends InvitationValidationResult {
  const InvitationNotFound();
}

/// La invitación fue revocada por el organizador.
final class InvitationRevoked extends InvitationValidationResult {
  const InvitationRevoked();
}

/// La invitación ha expirado.
final class InvitationExpired extends InvitationValidationResult {
  const InvitationExpired();
}

/// El torneo referenciado no existe o no es privado.
final class InvitationTournamentNotFound extends InvitationValidationResult {
  const InvitationTournamentNotFound();
}

/// El torneo ha alcanzado su capacidad máxima.
final class InvitationTournamentFull extends InvitationValidationResult {
  const InvitationTournamentFull({required this.tournament});

  final AppTournament tournament;
}
