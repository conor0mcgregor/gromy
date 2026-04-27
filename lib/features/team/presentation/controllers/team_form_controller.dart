import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../features/user/data/models/user_public_profile.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  TeamFormController  ·  Controlador del formulario de creación de equipo
//
//  Gestiona el estado multi-step (3 pasos):
//    Step 0 → Identidad (nombre + foto)
//    Step 1 → Miembros (buscar por nickname + toggle admin)
//    Step 2 → Resumen / Review
//
//  Sigue el mismo patrón que TournamentFormController.
// ─────────────────────────────────────────────────────────────────────────────

class TeamMemberEntry {
  const TeamMemberEntry({
    required this.uid,
    required this.nickname,
    required this.displayName,
    this.photoUrl,
    this.isAdmin = false,
  });

  final String uid;
  final String nickname;
  final String displayName;
  final String? photoUrl;
  final bool isAdmin;

  TeamMemberEntry copyWith({bool? isAdmin}) => TeamMemberEntry(
        uid: uid,
        nickname: nickname,
        displayName: displayName,
        photoUrl: photoUrl,
        isAdmin: isAdmin ?? this.isAdmin,
      );

  factory TeamMemberEntry.fromProfile(UserPublicProfile profile) =>
      TeamMemberEntry(
        uid: profile.uid,
        nickname: profile.nickname,
        displayName: '${profile.name} ${profile.lastName}'.trim(),
        photoUrl: profile.photoUrl,
      );
}

class TeamFormController extends ChangeNotifier {
  static const int totalSteps = 3;

  // ── Estado del paso actual ──
  int currentStep = 0;

  // ── Step 0: Identidad ──
  final nameController = TextEditingController();
  String? nameError;
  XFile? coverImage;
  Uint8List? coverBytes;

  // ── Step 1: Miembros ──
  final memberController = TextEditingController();
  String? memberError;
  bool isSearchingMember = false;
  final List<TeamMemberEntry> members = [];

  // ── Validación ──────────────────────────────────────────────────────────────

  bool validateCurrentStep() {
    switch (currentStep) {
      case 0:
        return _validateIdentity();
      case 1:
        return _validateMembers();
      case 2:
        return true; // Review, siempre válido
      default:
        return false;
    }
  }

  bool _validateIdentity() {
    final name = nameController.text.trim();
    final nameOk = name.isNotEmpty && name.length >= 3;

    nameError = name.isEmpty
        ? 'El nombre del equipo es obligatorio.'
        : name.length < 3
            ? 'El nombre debe tener al menos 3 caracteres.'
            : null;

    notifyListeners();
    return nameOk;
  }

  bool _validateMembers() {
    // No es obligatorio añadir miembros, pero validamos si hay error activo
    memberError = null;
    notifyListeners();
    return true;
  }

  // ── Navegación ──────────────────────────────────────────────────────────────

  bool goNext() {
    if (!validateCurrentStep()) return false;
    if (currentStep < totalSteps - 1) {
      currentStep++;
      notifyListeners();
      return true;
    }
    return false;
  }

  void goBack() {
    if (currentStep > 0) {
      currentStep--;
      notifyListeners();
    }
  }

  // ── Gestión de miembros ─────────────────────────────────────────────────────

  /// Añade un miembro si no está duplicado. Devuelve true si se añadió.
  bool addMember(TeamMemberEntry entry) {
    if (members.any((m) => m.uid == entry.uid)) {
      memberError = 'Este usuario ya ha sido añadido.';
      notifyListeners();
      return false;
    }
    members.add(entry);
    memberError = null;
    notifyListeners();
    return true;
  }

  void removeMember(String uid) {
    members.removeWhere((m) => m.uid == uid);
    memberError = null;
    notifyListeners();
  }

  void toggleMemberAdmin(String uid) {
    final index = members.indexWhere((m) => m.uid == uid);
    if (index != -1) {
      members[index] = members[index].copyWith(isAdmin: !members[index].isAdmin);
      notifyListeners();
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  void clearFieldError(String field) {
    switch (field) {
      case 'name':
        nameError = null;
        break;
      case 'member':
        memberError = null;
        break;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    nameController.dispose();
    memberController.dispose();
    super.dispose();
  }
}
