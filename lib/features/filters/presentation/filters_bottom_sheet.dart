import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../filters/domain/filter_model.dart';
import '../../filters/providers/filters_provider.dart';

/// Bottom sheet for selecting and adjusting filters
class FiltersBottomSheet extends ConsumerWidget {
  final bool isVideo;

  const FiltersBottomSheet({
    super.key,
    required this.isVideo,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filtersState = ref.watch(filtersProvider);
    final availableFilters = isVideo ? Filters.videoFilters : Filters.imageFilters;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'فلاتر',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    ref.read(filtersProvider.notifier).resetAllFilters();
                  },
                  child: const Text('إعادة تعيين'),
                ),
              ],
            ),
          ),

          const Divider(),

          // Filters list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: availableFilters.length,
              itemBuilder: (context, index) {
                final filter = availableFilters[index];
                return _FilterSliderTile(
                  filter: filter,
                  isVideo: isVideo,
                );
              },
            ),
          ),

          // Apply button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: filtersState.activeFilters.isEmpty
                    ? null
                    : () {
                        Navigator.pop(context);
                      },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  filtersState.activeFilters.isEmpty
                      ? 'اختر فلتر واحد على الأقل'
                      : 'تطبيق ${filtersState.activeFilters.length} فلتر',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual filter slider tile
class _FilterSliderTile extends ConsumerWidget {
  final FilterModel filter;
  final bool isVideo;

  const _FilterSliderTile({
    required this.filter,
    required this.isVideo,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filtersNotifier = ref.read(filtersProvider.notifier);
    final currentValue = filtersNotifier.getFilterValue(filter.type);
    final isActive = currentValue != filter.defaultValue;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter name and icon
            Row(
              children: [
                Icon(
                  filter.icon,
                  color: isActive
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey,
                ),
                const SizedBox(width: 12),
                Text(
                  filter.nameAr,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    color: isActive
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                ),
                const Spacer(),
                Text(
                  currentValue.toStringAsFixed(1),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Slider
            Slider(
              value: currentValue,
              min: filter.minValue,
              max: filter.maxValue,
              divisions: ((filter.maxValue - filter.minValue) * 10).toInt(),
              label: currentValue.toStringAsFixed(1),
              onChanged: (value) {
                filtersNotifier.updateFilter(filter.type, value);
              },
            ),

            // Min/Max labels
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  filter.minValue.toString(),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (filter.unit.isNotEmpty)
                  Text(
                    filter.unit,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                Text(
                  filter.maxValue.toString(),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
