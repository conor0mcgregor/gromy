import 'package:flutter/material.dart';

import '../../data/models/local_athlete.dart';
import '../controllers/local_tournament_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  LocalTournamentAthletesScreen  ·  Presentation
//
//  Gestión de atletas para un torneo local.
//  Diseñado para que el organizador pueda inscribir atletas de forma ultra rápida:
//  - Solo solicita el NOMBRE
//  - Entrada rápida y consecutiva (tecla enter o botón "Añadir" mantiene el foco)
//  - Añadir múltiples atletas separándolos por saltos de línea / coma
//  - Identificador único automático e independiente de Firebase
//  - Permite nombres duplicados (mismo nombre, diferente ID)
//  - Edición y eliminación ágiles con confirmación
// ─────────────────────────────────────────────────────────────────────────────

class LocalTournamentAthletesScreen extends StatefulWidget {
  const LocalTournamentAthletesScreen({
    super.key,
    required this.controller,
  });

  final LocalTournamentController controller;

  @override
  State<LocalTournamentAthletesScreen> createState() =>
      _LocalTournamentAthletesScreenState();
}

class _LocalTournamentAthletesScreenState
    extends State<LocalTournamentAthletesScreen> {
  final _nameController = TextEditingController();
  final _focusNode = FocusNode();
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _focusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _addAthleteSingle() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    widget.controller.addAthlete(name);
    _nameController.clear();
    // Mantener el foco en el campo para añadir el siguiente inmediatamente
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final athletes = widget.controller.athletes;
        final filtered = _searchQuery.isEmpty
            ? athletes
            : athletes
                .where((a) =>
                    a.name.toLowerCase().contains(_searchQuery.toLowerCase()))
                .toList();

        return Scaffold(
          backgroundColor: const Color(0xFF0F172A),
          appBar: AppBar(
            backgroundColor: const Color(0xFF0F172A),
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white.withValues(alpha: 0.06),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Icon(Icons.arrow_back_rounded,
                    size: 18, color: Colors.white.withValues(alpha: 0.8)),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Atletas del torneo',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${athletes.length} participante${athletes.length == 1 ? '' : 's'}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Añadir varios a la vez',
                icon: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0xFF6C63FF).withValues(alpha: 0.15),
                    border: Border.all(
                        color: const Color(0xFF6C63FF).withValues(alpha: 0.3)),
                  ),
                  child: const Icon(Icons.playlist_add_rounded,
                      size: 18, color: Color(0xFF6C63FF)),
                ),
                onPressed: _showBulkAddDialog,
              ),
              const SizedBox(width: 12),
            ],
          ),
          body: Column(
            children: [
              // ── Campo de Registro Rápido ──
              _buildQuickInputField(),

              // ── Barra de búsqueda si hay más de 5 atletas ──
              if (athletes.length > 5) _buildSearchBar(),

              // ── Lista de Atletas ──
              Expanded(
                child: filtered.isEmpty
                    ? _buildEmptyState(athletes.isEmpty)
                    : _buildAthletesList(filtered),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickInputField() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF6C63FF).withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.person_add_rounded,
              color: Color(0xFF6C63FF), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _nameController,
              focusNode: _focusNode,
              autofocus: true,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: 'Nombre del atleta (ej. Carlos, Alex...)',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.35),
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _addAthleteSingle(),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _addAthleteSingle,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_rounded, size: 16),
                SizedBox(width: 4),
                Text(
                  'Añadir',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        onChanged: (val) => setState(() => _searchQuery = val.trim()),
        decoration: InputDecoration(
          hintText: 'Buscar atleta...',
          hintStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.3),
            fontSize: 13,
          ),
          prefixIcon: Icon(Icons.search_rounded,
              size: 18, color: Colors.white.withValues(alpha: 0.4)),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 16),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.03),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF6C63FF)),
          ),
        ),
      ),
    );
  }

  Widget _buildAthletesList(List<LocalAthlete> athletes) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      itemCount: athletes.length,
      separatorBuilder: (_, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final athlete = athletes[index];
        return _AthleteListTile(
          athlete: athlete,
          index: index + 1,
          onEdit: () => _showEditDialog(athlete),
          onDelete: () => _confirmDelete(athlete),
        );
      },
    );
  }

  Widget _buildEmptyState(bool noAthletesAtAll) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
              ),
              child: const Icon(
                Icons.people_outline_rounded,
                size: 36,
                color: Color(0xFF6C63FF),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              noAthletesAtAll
                  ? 'Sin atletas inscritos'
                  : 'Ningún atleta coincide con "$_searchQuery"',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              noAthletesAtAll
                  ? 'Introduce el nombre en el campo superior para inscribir al primer participante.'
                  : 'Prueba con otro término de búsqueda.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 13,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditDialog(LocalAthlete athlete) async {
    final controller = TextEditingController(text: athlete.name);
    final formKey = GlobalKey<FormState>();

    final updated = await showDialog<String>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Editar nombre del atleta',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: controller,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Nombre',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 1.5),
                    ),
                  ),
                  validator: (v) =>
                      (v?.trim().isEmpty ?? true) ? 'El nombre no puede estar vacío' : null,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(
                          'Cancelar',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (formKey.currentState!.validate()) {
                            Navigator.pop(ctx, controller.text.trim());
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C63FF),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text('Guardar',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (updated != null && updated.isNotEmpty && mounted) {
      widget.controller.editAthlete(athlete.id, updated);
    }
  }

  Future<void> _confirmDelete(LocalAthlete athlete) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                ),
                child: const Icon(Icons.delete_outline_rounded,
                    color: Color(0xFFEF4444), size: 26),
              ),
              const SizedBox(height: 14),
              const Text(
                'Eliminar participante',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '¿Deseas eliminar a "${athlete.name}" del torneo?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text('Cancelar',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.6))),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Eliminar',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true && mounted) {
      widget.controller.removeAthlete(athlete.id);
    }
  }

  Future<void> _showBulkAddDialog() async {
    final bulkController = TextEditingController();

    final result = await showDialog<List<String>>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: const Color(0xFF6C63FF).withValues(alpha: 0.15),
                    ),
                    child: const Icon(Icons.playlist_add_rounded,
                        color: Color(0xFF6C63FF), size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Añadir varios atletas',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Escribe o pega los nombres de los atletas, uno por línea o separados por comas:',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 12.5,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: bulkController,
                maxLines: 6,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Carlos\nAna García\nMarcos\nElena',
                  hintStyle:
                      TextStyle(color: Colors.white.withValues(alpha: 0.25)),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: Color(0xFF6C63FF), width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text('Cancelar',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6))),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final raw = bulkController.text;
                        final parsed = raw
                            .split(RegExp(r'[\n,]+'))
                            .map((s) => s.trim())
                            .where((s) => s.isNotEmpty)
                            .toList();
                        Navigator.pop(ctx, parsed);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C63FF),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Inscribir todos',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (result != null && result.isNotEmpty && mounted) {
      widget.controller.addAthletes(result);
    }
  }
}

// ── Item individual de atleta ────────────────────────────────────────────────

class _AthleteListTile extends StatelessWidget {
  const _AthleteListTile({
    required this.athlete,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });

  final LocalAthlete athlete;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(
        children: [
          // Número de orden / Avatar
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF6C63FF).withValues(alpha: 0.15),
              border: Border.all(
                color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
              ),
            ),
            child: Center(
              child: Text(
                '$index',
                style: const TextStyle(
                  color: Color(0xFF6C63FF),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Nombre
          Expanded(
            child: Text(
              athlete.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Botón editar
          IconButton(
            icon: Icon(Icons.edit_outlined,
                size: 18, color: Colors.white.withValues(alpha: 0.45)),
            onPressed: onEdit,
            tooltip: 'Editar nombre',
            visualDensity: VisualDensity.compact,
          ),
          // Botón eliminar
          IconButton(
            icon: Icon(Icons.delete_outline_rounded,
                size: 18, color: const Color(0xFFEF4444).withValues(alpha: 0.7)),
            onPressed: onDelete,
            tooltip: 'Eliminar participante',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
