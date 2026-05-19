import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../database/team/models/app_team.dart';
import '../../../../database/team/services/firestore_team_service.dart';
import '../../data/services/team_storage_service.dart';
import '../../../notifications/data/repository/team_invitation_repository_impl.dart';
import '../../../notifications/domain/use_cases/team_invitation_use_cases.dart';
import 'team_form_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  CreateTeamController  ·  Responsable de persistir el equipo en Firestore
//
//  Sigue el patrón de CreateTournamentController: recibe los datos del
//  formulario y orquesta la escritura en la base de datos.
//
//  Flujo de membresía (refactorizado):
//  1. El creador se añade como único miembro directo
//  2. Otros usuarios del formulario reciben INVITACIONES via Cloud Function
//  3. Se convierten en miembros solo cuando acepten la invitación
//
//  Flujo de la imagen:
//  1. Se crea el equipo en Firestore (sin foto) para obtener el ID
//  2. Si hay imagen, se sube a Firebase Storage con el teamId
//  3. Se obtiene la URL de descarga
//  4. Se actualiza el equipo en Firestore con la URL de la foto
// ─────────────────────────────────────────────────────────────────────────────

class CreateTeamController extends ChangeNotifier {
  CreateTeamController({
    FirestoreTeamService? teamService,
    TeamStorageService? storageService,
    CloudFunctionTeamInvitationRepository? invitationRepo,
  })  : _teamService = teamService ?? FirestoreTeamService(),
        _storageService = storageService ?? TeamStorageService(),
        _invitationRepo = invitationRepo ?? CloudFunctionTeamInvitationRepository();

  final FirestoreTeamService _teamService;
  final TeamStorageService _storageService;
  final CloudFunctionTeamInvitationRepository _invitationRepo;

  bool _isSubmitting = false;
  String? _error;

  /// IDs de invitaciones enviadas exitosamente durante la última creación.
  final List<String> _sentInvitationIds = [];

  bool get isSubmitting => _isSubmitting;
  String? get error => _error;

  /// Crea el equipo a partir del estado del formulario.
  ///
  /// Solo el creador se añade directamente como miembro.
  /// Los demás miembros del formulario reciben invitaciones.
  ///
  /// Devuelve el [AppTeam] creado o null si falla.
  Future<AppTeam?> submitTeam(TeamFormController form) async {
    _isSubmitting = true;
    _error = null;
    _sentInvitationIds.clear();
    notifyListeners();

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        _error = 'No se pudo obtener el usuario actual.';
        return null;
      }

      final creatorId = currentUser.uid;
      final teamName = form.nameController.text.trim();

      // Solo el creador como miembro inicial (resto recibirán invitación)
      final memberUids = <String>[creatorId];
      final adminUids = <String>[creatorId];

      // 1. Crear el equipo en Firestore (sin foto, para obtener el ID)
      final team = AppTeam(
        id: '',
        name: teamName,
        creatorId: creatorId,
        members: memberUids,
        adminIds: adminUids,
        createdAt: DateTime.now(),
      );

      var created = await _teamService.createTeam(team);

      // 2. Si hay imagen, subirla a Storage y actualizar el equipo
      if (form.coverImage != null) {
        try {
          final photoUrl = await _storageService.uploadTeamPhoto(
            teamId: created.id,
            imageFile: form.coverImage!,
          );

          created = created.copyWith(photoUrl: photoUrl);
          await _teamService.updateTeam(created);
        } catch (e) {
          // La imagen falló pero el equipo se creó → no es un error fatal
          debugPrint('Error subiendo foto del equipo: $e');
        }
      }

      // 3. Enviar invitaciones a los miembros del formulario (excepto el creador)
      final sendUseCase = SendTeamInvitationUseCase(_invitationRepo);
      for (final member in form.members) {
        if (member.uid == creatorId) continue;
        try {
          final notifId = await sendUseCase(
            teamId: created.id,
            invitedUserId: member.uid,
          );
          _sentInvitationIds.add(notifId);
          debugPrint(
            '[CreateTeamController] Invitación enviada a ${member.uid}: $notifId',
          );
        } catch (e) {
          // Una invitación fallida no bloquea la creación del equipo
          debugPrint(
            '[CreateTeamController] Error enviando invitación a ${member.uid}: $e',
          );
        }
      }

      return created;
    } catch (e) {
      _error = 'No se pudo crear el equipo. Inténtalo de nuevo.';
      return null;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
