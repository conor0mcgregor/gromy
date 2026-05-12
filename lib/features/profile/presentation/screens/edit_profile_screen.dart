import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:gromy/core/widgets/gradient_button.dart';
import 'package:gromy/core/widgets/glass_text_field.dart';
import 'package:gromy/core/widgets/bar_small_botton.dart';
import '../controllers/edit_profile_controller.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required this.uid});
  final String uid;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final EditProfileController _controller;

  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _bioController = TextEditingController();

  String? _nameError;
  String? _lastNameError;
  String? _nicknameError;

  XFile? _pickedImage;

  @override
  void initState() {
    super.initState();
    _controller = EditProfileController(uid: widget.uid);
    _controller.addListener(_onControllerUpdate);
    _loadData();
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _loadData() async {
    await _controller.loadUser();
    final user = _controller.user;
    if (user != null) {
      _nameController.text = user.name;
      _lastNameController.text = user.lastName;
      _nicknameController.text = user.nickname;
      _bioController.text = user.biography ?? '';
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _nameController.dispose();
    _lastNameController.dispose();
    _nicknameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _handlePickImage() async {
    final image = await _controller.pickImage();
    if (image != null) {
      setState(() {
        _pickedImage = image;
      });
    }
  }

  Widget _buildLabeledField(String label, Widget field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        field,
      ],
    );
  }

  Future<void> _handleSave() async {
    // Hide keyboard
    FocusScope.of(context).unfocus();

    setState(() {
      _nameError = _nameController.text.trim().isEmpty ? 'Ingresa tu nombre' : null;
      _lastNameError = _lastNameController.text.trim().isEmpty ? 'Ingresa tus apellidos' : null;

      final nickname = _nicknameController.text.trim();
      if (nickname.isEmpty) {
        _nicknameError = 'Ingresa un alias';
      } else if (nickname.length < 3) {
        _nicknameError = 'Mínimo 3 caracteres';
      } else {
        _nicknameError = null;
      }
    });

    if (_nameError != null || _lastNameError != null || _nicknameError != null) {
      return;
    }

    final success = await _controller.saveProfile(
      name: _nameController.text,
      lastName: _lastNameController.text,
      nickname: _nicknameController.text,
      biography: _bioController.text,
      newImage: _pickedImage,
    );

    if (success && mounted) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil actualizado correctamente.'),
          backgroundColor: Color(0xFF22C55E),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Column(
          children: [
            // AppBar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  BarSmallBotton(
                    icon: Icons.arrow_back_ios_new,
                    onTap: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Editar Perfil',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _controller.isLoading && _controller.user == null
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)))
                  : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Error Message
                    if (_controller.errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF4D6A).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFFFF4D6A).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          _controller.errorMessage!,
                          style: const TextStyle(color: Color(0xFFFF4D6A), fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Avatar selector
                    Center(
                      child: GestureDetector(
                        onTap: _handlePickImage,
                        child: Stack(
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.05),
                                border: Border.all(
                                  color: const Color(0xFF6C63FF).withValues(alpha: 0.5),
                                  width: 2,
                                ),
                                image: _pickedImage != null
                                    ? DecorationImage(
                                  image: FileImage(File(_pickedImage!.path)),
                                  fit: BoxFit.cover,
                                )
                                    : _controller.user?.photoUrl != null
                                    ? DecorationImage(
                                  image: NetworkImage(_controller.user!.photoUrl!),
                                  fit: BoxFit.cover,
                                )
                                    : null,
                              ),
                              child: _pickedImage == null && _controller.user?.photoUrl == null
                                  ? const Icon(Icons.person_rounded, size: 50, color: Colors.white)
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF6C63FF),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Inputs
                    _buildLabeledField(
                      'Nombre',
                      GlassTextField(
                        hint: 'Tu nombre',
                        controller: _nameController,
                        icon: Icons.person_outline_rounded,
                        errorText: _nameError,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildLabeledField(
                      'Apellidos',
                      GlassTextField(
                        hint: 'Tus apellidos',
                        controller: _lastNameController,
                        icon: Icons.person_outline_rounded,
                        errorText: _lastNameError,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildLabeledField(
                      'Alias',
                      GlassTextField(
                        hint: 'ej. jugador_pro',
                        controller: _nicknameController,
                        icon: Icons.alternate_email_rounded,
                        errorText: _nicknameError,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildLabeledField(
                      'Biografía',
                      GlassTextField(
                        hint: 'Cuéntanos sobre ti...',
                        controller: _bioController,
                        icon: Icons.info_outline_rounded,
                        maxLines: 4,
                      ),
                    ),
                    const SizedBox(height: 40),

                    GradientButton(
                      onPressed: _controller.isLoading ? null : _handleSave,
                      label: _controller.isLoading ? 'Guardando...' : 'Guardar Cambios',
                      isLoading: _controller.isLoading,
                      icon: Icons.save_rounded,
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
