import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../screens/map_picker_screen.dart';

/// Menú inferior (BottomSheet) para filtros avanzados
class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({
    super.key,
    required this.availableSports,
    required this.initialSport,
    required this.initialDateRange,
    required this.initialLocation,
    required this.initialRadius,
    required this.initialParticipants,
    required this.onApply,
  });

  final List<String> availableSports;
  final String? initialSport;
  final DateTimeRange? initialDateRange;
  final LatLng? initialLocation;
  final double? initialRadius;
  final int? initialParticipants;
  final Function(String?, DateTimeRange?, LatLng?, double?, int?) onApply;

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  String? _selectedSportModal;
  DateTimeRange? _selectedDateRange;
  LatLng? _selectedLocation;
  double? _selectedRadiusKm;
  late final TextEditingController _participantsController;

  @override
  void initState() {
    super.initState();
    _selectedSportModal = widget.initialSport;
    _selectedDateRange = widget.initialDateRange;
    _selectedLocation = widget.initialLocation;
    _selectedRadiusKm = widget.initialRadius;
    _participantsController = TextEditingController(
      text: widget.initialParticipants?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _participantsController.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF6C63FF),
              onPrimary: Colors.white,
              surface: Color(0xFF1E1E2C),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Padding para que el teclado no tape el contenido
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF12122E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Grabber
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Filtros Avanzados',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Módulo de Deportes
              Text(
                'Deporte',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.availableSports.map((sport) {
                  final isSelected = _selectedSportModal == sport;
                  return GestureDetector(
                    onTap: () => setState(() {
                      if (_selectedSportModal == sport) {
                        _selectedSportModal = null;
                      } else {
                        _selectedSportModal = sport;
                      }
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF6C63FF) : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? Colors.transparent : Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Text(
                        sport,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.6),
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Módulo de Rango de Fechas
              Text(
                'Rango de Fechas',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickDateRange,
                child: Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.date_range_rounded, color: Colors.white.withValues(alpha: 0.4), size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedDateRange == null
                              ? 'Cualquier fecha'
                              : '${_selectedDateRange!.start.day}/${_selectedDateRange!.start.month}/${_selectedDateRange!.start.year} - ${_selectedDateRange!.end.day}/${_selectedDateRange!.end.month}/${_selectedDateRange!.end.year}',
                          style: const TextStyle(color: Colors.white, fontSize: 15),
                        ),
                      ),
                      if (_selectedDateRange != null)
                        GestureDetector(
                          onTap: () => setState(() => _selectedDateRange = null),
                          child: Icon(Icons.close_rounded, color: Colors.white.withValues(alpha: 0.4), size: 20),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Módulo de Ubicación Espacial
              Text(
                'Ubicación de Referencia',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14),
              ),
              const SizedBox(height: 8),
              if (_selectedLocation == null)
                _BottomSheetActionButton(
                  icon: Icons.map_rounded,
                  label: 'Seleccionar Ubicación',
                  onTap: () async {
                    final picked = await Navigator.push<(LatLng, double)?>(context, MaterialPageRoute(builder: (_) => MapPickerScreen(initialPoint: _selectedLocation, initialRadius: _selectedRadiusKm ?? 10.0)));
                    if (picked != null && mounted) {
                      setState(() {
                        _selectedLocation = picked.$1;
                        _selectedRadiusKm = picked.$2;
                      });
                    }
                  },
                )
              else
                GestureDetector(
                  onTap: () async {
                    final picked = await Navigator.push<(LatLng, double)?>(
                        context,
                        MaterialPageRoute(
                            builder: (_) => MapPickerScreen(
                                initialPoint: _selectedLocation,
                                initialRadius: _selectedRadiusKm ?? 10.0
                            )
                        )
                    );
                    if (picked != null && mounted) {
                      setState(() {
                        _selectedLocation = picked.$1;
                        _selectedRadiusKm = picked.$2;
                      });
                    }
                  },
                  child: Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C63FF).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF6C63FF).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.place_rounded, color: Color(0xFFB0A8FF), size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Coordenadas guardadas (${_selectedRadiusKm?.toInt()} km)',
                            style: const TextStyle(color: Colors.white, fontSize: 15),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() {
                            _selectedLocation = null;
                            _selectedRadiusKm = null;
                          }),
                          child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 20),

              // Módulo de Participantes
              Text(
                'Límite de participantes (hasta)',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14),
              ),
              const SizedBox(height: 8),
              Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: TextField(
                  controller: _participantsController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Ej. 16, 32...',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Botones Aplicar / Limpiar
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _selectedSportModal = null;
                          _selectedDateRange = null;
                          _selectedLocation = null;
                          _selectedRadiusKm = null;
                          _participantsController.clear();
                        });
                        widget.onApply(null, null, null, null, null);
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Limpiar', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF00D4FF)]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          widget.onApply(
                            _selectedSportModal,
                            _selectedDateRange,
                            _selectedLocation,
                            _selectedRadiusKm,
                            int.tryParse(_participantsController.text.trim()),
                          );
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Aplicar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomSheetActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isLoading;

  const _BottomSheetActionButton({required this.icon, required this.label, required this.onTap, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            else
              Icon(icon, color: Colors.white.withValues(alpha: 0.4), size: 18),
            const SizedBox(width: 8),
            Text(isLoading ? '...' : label, style: const TextStyle(color: Colors.white, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
