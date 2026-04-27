import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../database/team/models/app_team.dart';
import '../../../../database/team/services/firestore_team_service.dart';
import 'team_form_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  CreateTeamController  ·  Responsable de persistir el equipo en Firestore
//
//  Sigue el patrón de CreateTournamentController: recibe los datos del
//  formulario y orquesta la escritura en la base de datos.
// ─────────────────────────────────────────────────────────────────────────────

class CreateTeamController extends ChangeNotifier {
  CreateTeamController({FirestoreTeamService? teamService})
      : _teamService = teamService ?? FirestoreTeamService();

  final FirestoreTeamService _teamService;

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

      final team = AppTeam(
        id: '',
        name: teamName,
        creatorId: creatorId,
        members: memberUids,
        adminIds: adminUids,
        createdAt: DateTime.now(),
        // photoUrl se dejará null por ahora (sin Storage)
      );

      final created = await _teamService.createTeam(team);
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
