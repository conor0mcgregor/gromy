import 'package:flutter/material.dart';
import '../../../../data/services/geocoding_service.dart';
import 'form_fields.dart';
import 'form_helpers.dart';

/// Campo de búsqueda de ubicación con autocompletado usando Nominatim.
///
/// Muestra sugerencias en un desplegable estilizado debajo del campo de texto.
class LocationSearchField extends StatelessWidget {
  const LocationSearchField({
    super.key,
    required this.controller,
    required this.errorText,
    required this.suggestions,
    required this.isSearching,
    required this.onQueryChanged,
    required this.onSuggestionSelected,
  });

  final TextEditingController controller;
  final String? errorText;
  final List<GeocodingResult> suggestions;
  final bool isSearching;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<GeocodingResult> onSuggestionSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlassField(
          controller: controller,
          hint: 'Busca una dirección, ciudad o lugar...',
          icon: Icons.search_rounded,
          label: 'Ubicación',
          errorText: errorText,
          capitalization: TextCapitalization.words,
          onChanged: onQueryChanged,
        ),

        // ── Indicador de carga ──
        if (isSearching)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Buscando...',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

        // ── Lista de sugerencias ──
        if (suggestions.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 220),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: const Color(0xFF161640),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: suggestions.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
                itemBuilder: (context, index) {
                  final item = suggestions[index];
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => onSuggestionSelected(item),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: const Color(0xFF6C63FF)
                                    .withValues(alpha: 0.15),
                              ),
                              child: const Icon(
                                Icons.place_rounded,
                                color: Color(0xFF6C63FF),
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item.displayName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 13,
                                  height: 1.35,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.north_east_rounded,
                              color: Colors.white.withValues(alpha: 0.25),
                              size: 14,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ],
    );
  }
}
