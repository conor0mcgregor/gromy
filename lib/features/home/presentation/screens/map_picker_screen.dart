import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../../tournament/presentation/controllers/location_picker_controller.dart';
import '../../../tournament/presentation/screens/create_tournament/form/widgets/location_picker_map.dart';

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key, this.initialPoint, required this.initialRadius});
  final LatLng? initialPoint;
  final double initialRadius;

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  late LocationPickerController _controller;
  late double _radius;
  final List<double> _radiusOptions = [5.0, 10.0, 25.0, 50.0];

  @override
  void initState() {
    super.initState();
    _radius = widget.initialRadius;
    _controller = LocationPickerController(
      initialPoint: widget.initialPoint,
      fallbackCenter: const LatLng(40.4168, -3.7038), // Madrid
      onLocationConfirmed: (_) async {},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Filtro de Ubicación', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF1E1E2C),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      backgroundColor: const Color(0xFF1E1E2C),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: LocationPickerMap(
                  controller: _controller,
                  radiusKm: _radius,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: const BoxDecoration(
                color: Color(0xFF12122E),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Rango de búsqueda', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: _radiusOptions.map((r) {
                      final isSelected = _radius == r;
                      return GestureDetector(
                        onTap: () => setState(() => _radius = r),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF6C63FF) : Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isSelected ? Colors.transparent : Colors.white.withValues(alpha: 0.1)),
                          ),
                          child: Text('${r.toInt()} km', style: TextStyle(color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.6), fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500)),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_controller.selectedPoint != null) {
                          Navigator.pop(context, (_controller.selectedPoint!, _radius));
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecciona un punto en el mapa', style: TextStyle(color: Colors.white))));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C63FF),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Confirmar', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
