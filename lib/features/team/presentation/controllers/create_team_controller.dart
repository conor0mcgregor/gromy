import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../database/team/models/app_team.dart';
import '../../../../database/team/services/firestore_team_service.dart';
import '../../data/services/team_storage_service.dart';
import 'team_form_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  CreateTeamController  ·  Responsable de persistir el equipo en Firestore
//
//  Sigue el patrón de CreateTournamentController: recibe los datos del
//  formulario y orquesta la escritura en la base de datos.
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
  })  : _teamService = teamService ?? FirestoreTeamService(),
        _storageService = storageService ?? TeamStorageService();

  final FirestoreTeamService _teamService;
  final TeamStorageService _storageService;

  bool _isSubmitting = false;
  String? _error;

  bool get isSubmitting => _isSubmitting;
  String? get error => _error;

  /// Crea el equipo a partir del estado del formulario.
  /// Devuelve el [AppTeam] creado o null si falla.
  Future<AppTeam?> submitTeam(TeamFormController form) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        _error = 'No se pudo obtener el usuario actual.';
        return null;
      }

      final creatorId = currentUser.uid;
      final teamName = form.nameController.text.trim();

      // El creador siempre es miembro y admin
      final memberUids = <String>[creatorId];
      final adminUids = <String>[creatorId];

      for (final member in form.members) {
        if (!memberUids.contains(member.uid)) {
          memberUids.add(member.uid);
        }
        if (member.isAdmin && !adminUids.contains(member.uid)) {
          adminUids.add(member.uid);
        }
      }

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

          // 3. Actualizar el equipo con la URL de la foto
          created = created.copyWith(photoUrl: photoUrl);
          await _teamService.updateTeam(created);
        } catch (e) {
          // La imagen falló pero el equipo se creó → no es un error fatal
          // El usuario puede cambiar la foto más tarde desde gestión
          debugPrint('Error subiendo foto del equipo: $e');
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
