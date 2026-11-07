import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/regional_catalog.dart';
import '../../domain/services/material_recommender.dart';
import '../../domain/value_objects/measurement_unit.dart';
import '../providers/designer_providers.dart';
import '../providers/project_context_provider.dart';
import 'help_tooltip.dart';
import 'pricing_editor_dialog.dart';
import 'surface_card.dart';

class RegionalMaterialPanel extends ConsumerWidget {
  const RegionalMaterialPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncContext = ref.watch(projectContextProvider);
    final controller = ref.read(projectContextProvider.notifier);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final project = asyncContext.asData?.value;
    if (project == null) {
      if (asyncContext.hasError) {
        return SurfaceCard(
          child: Text(
            'No se pudo cargar la configuración regional: ${asyncContext.error}',
            key: const Key('regional_config_error'),
            style: theme.textTheme.bodySmall?.copyWith(color: scheme.error),
          ),
        );
      }
      return const SurfaceCard(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 10),
                Text('Cargando país, materiales y precios…'),
              ],
            ),
          ),
        ),
      );
    }

    final recommendations = ref.watch(materialRecommendationsProvider);
    final materialCatalog = ref.watch(materialCatalogProvider);
    final country = project.country;

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'País, lugar y material',
                  style: theme.textTheme.titleLarge,
                ),
              ),
              const HelpTooltip(
                message: 'El clima y el uso cambian qué material conviene. En baños o zonas húmedas evita el MDF o aglomerado estándar.',
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Elige las condiciones reales de uso; las medidas internas siguen en milímetros.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 520 ? 2 : 1;
              final fields = [
                DropdownButtonFormField<String>(
                  key: const Key('country_selector'),
                  isExpanded: true,
                  initialValue: country.code,
                  decoration: const InputDecoration(labelText: 'País'),
                  items: [
                    for (final item in project.catalog.countries)
                      DropdownMenuItem(
                        value: item.code,
                        child: Text(item.name),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) controller.selectCountry(value);
                  },
                ),
                DropdownButtonFormField<MeasurementUnit>(
                  key: const Key('unit_selector'),
                  isExpanded: true,
                  initialValue: project.unit,
                  decoration: const InputDecoration(
                    labelText: 'Unidad de entrada',
                  ),
                  items: [
                    for (final unit in MeasurementUnit.values)
                      DropdownMenuItem(value: unit, child: Text(unit.label)),
                  ],
                  onChanged: (value) {
                    if (value != null) controller.selectUnit(value);
                  },
                ),
                DropdownButtonFormField<String>(
                  key: const Key('climate_selector'),
                  isExpanded: true,
                  initialValue: project.climateId,
                  decoration: const InputDecoration(labelText: 'Clima'),
                  items: [
                    for (final ClimateOption climate
                        in project.catalog.climates)
                      DropdownMenuItem(
                        value: climate.id,
                        child: Text(climate.label),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) controller.selectClimate(value);
                  },
                ),
                DropdownButtonFormField<String>(
                  key: const Key('place_use_selector'),
                  isExpanded: true,
                  initialValue: project.useId,
                  decoration: const InputDecoration(labelText: 'Uso/lugar'),
                  items: [
                    for (final PlaceUseOption use in project.catalog.uses)
                      DropdownMenuItem(value: use.id, child: Text(use.label)),
                  ],
                  onChanged: (value) {
                    if (value != null) controller.selectUse(value);
                  },
                ),
                DropdownButtonFormField<double>(
                  key: const Key('kerf_selector'),
                  isExpanded: true,
                  initialValue: project.kerfMm,
                  decoration: const InputDecoration(
                    labelText: 'Kerf de sierra',
                  ),
                  items: const [3.0, 3.2, 4.0]
                      .map(
                        (kerf) => DropdownMenuItem(
                          value: kerf,
                          child: Text('${kerf.toStringAsFixed(1)} mm'),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value != null) controller.selectKerf(value);
                  },
                ),
              ];
              return Wrap(
                spacing: 12,
                runSpacing: 10,
                children: [
                  for (final field in fields)
                    SizedBox(
                      width: columns == 2
                          ? (constraints.maxWidth - 12) / 2
                          : constraints.maxWidth,
                      child: field,
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            '${country.currency} · impuesto ${country.standardTaxPercent == null ? 'local configurable' : '${country.standardTaxPercent!.toStringAsFixed(0)}% ${country.taxName}'} · tableros: ${country.boardSizes.map((size) => size.label).join(', ')}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          Text(
            country.taxNote,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          if (country.taxSource.isNotEmpty)
            Text(
              'Referencia: ${country.taxSource} · ${country.taxUpdatedAt}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          const Divider(height: 22),
          Row(
            children: [
              Icon(Icons.eco_outlined, size: 19, color: scheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Materiales recomendados',
                  style: theme.textTheme.titleSmall,
                ),
              ),
              Text('2–3 opciones', style: theme.textTheme.labelSmall),
            ],
          ),
          const SizedBox(height: 8),
          for (final recommendation in recommendations)
            _RecommendationTile(
              recommendation: recommendation,
              priceAvailable:
                  recommendation.material.catalogMaterialId != null &&
                  (materialCatalog
                              .byId(recommendation.material.catalogMaterialId!)
                              ?.priceCents ??
                          0) >
                      0,
            ),
          const SizedBox(height: 6),
          Text(
            country.priceDataNote,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              key: const Key('regional_prices_button'),
              onPressed: () => showPricingEditorDialog(context, ref),
              icon: const Icon(Icons.price_change_outlined, size: 18),
              label: Text('Editar precios ${country.currency}'),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendationTile extends StatelessWidget {
  final MaterialRecommendation recommendation;
  final bool priceAvailable;

  const _RecommendationTile({
    required this.recommendation,
    required this.priceAvailable,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final profile = recommendation.material;
    final pros = profile.pros.join(' · ');
    final cons = profile.cons.join(' · ');
    final relativeCost = priceAvailable
        ? 'costo ${profile.costBand}'
        : 'costo ${profile.costBand}; precio local por cotizar';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${recommendation.rank}. ${profile.name} · $relativeCost',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text('A favor: $pros', style: theme.textTheme.bodySmall),
          Text(
            'Precaución: $cons',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
