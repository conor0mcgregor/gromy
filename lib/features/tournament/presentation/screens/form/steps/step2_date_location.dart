import 'package:flutter/material.dart';
import '../widgets/step_card.dart';
import '../widgets/form_fields.dart';
import '../widgets/form_helpers.dart';

class Step2DateLocation extends StatelessWidget {
  const Step2DateLocation({
    super.key,
    required this.selectedDate,
    required this.dateError,
    required this.onPickDate,
    required this.locationController,
    required this.locationError,
    required this.onLocationChanged,
  });

  final DateTime? selectedDate;
  final String? dateError;
  final VoidCallback onPickDate;

  final TextEditingController locationController;
  final String? locationError;
  final ValueChanged<String>? onLocationChanged;

  String _formatDate(DateTime date) {
    const months = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
    ];
    return '${date.day} de ${months[date.month - 1]} de ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return StepCard(
      icon: Icons.event_rounded,
      title: 'Cuándo y dónde',
      subtitle: 'Indica la fecha y el lugar donde se celebrará el torneo.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selector de fecha
          const FieldLabel(label: 'Fecha del torneo'),
          const SizedBox(height: 8),
          PickerTile(
            icon: Icons.calendar_month_rounded,
            value: selectedDate == null
                ? 'Elige una fecha'
                : _formatDate(selectedDate!),
            isEmpty: selectedDate == null,
            errorText: dateError,
            onTap: onPickDate,
          ),
          const SizedBox(height: 16),

          // Campo lugar
          GlassField(
            controller: locationController,
            hint: 'Ciudad, pabellón o dirección',
            icon: Icons.location_on_outlined,
            label: 'Lugar',
            errorText: locationError,
            capitalization: TextCapitalization.words,
            onChanged: onLocationChanged,
          ),
        ],
      ),
    );
  }
}
