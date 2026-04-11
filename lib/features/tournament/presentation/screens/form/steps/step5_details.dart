import 'package:flutter/material.dart';
import '../widgets/step_card.dart';
import '../widgets/form_fields.dart';

class Step5Details extends StatelessWidget {
  const Step5Details({
    super.key,
    required this.completeInformationController,
    required this.completeInfoError,
    required this.onInfoChanged,
  });

  final TextEditingController completeInformationController;
  final String? completeInfoError;
  final ValueChanged<String>? onInfoChanged;

  @override
  Widget build(BuildContext context) {
    return StepCard(
      icon: Icons.text_snippet,
      title: 'Información completa',
      subtitle: 'Especifica toda la información, detalles, reglas, datos, etc... del torneo.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlassField(
            controller: completeInformationController,
            hint: 'Información adicional (mínimo 100 caracteres)\nReglas del torneo, fechas clave...',
            icon: Icons.text_snippet,
            label: 'Información completa',
            errorText: completeInfoError,
            minLines: 5,
            maxLines: 15,
            onChanged: onInfoChanged,
          ),
        ],
      ),
    );
  }
}
