import 'package:flutter/material.dart';

import '../../domain/filter_theme.dart';

class FilterCard extends StatelessWidget {
  const FilterCard({
    super.key,
    required this.filter,
    required this.isSelected,
    required this.onTap,
  });

  final FilterTheme filter;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected
        ? Theme.of(context).colorScheme.primary
        : Colors.transparent;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 2),
          color: Theme.of(context).cardColor,
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: borderColor.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: filter.backgroundColor ?? Colors.black,
                  gradient: filter.gradientColors != null
                      ? LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: filter.gradientColors!,
                        )
                      : null,
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Subtle Pattern Overlay
                    Opacity(
                      opacity: 0.1,
                      child: Icon(Icons.grid_on, color: filter.textColor, size: 100),
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_stories,
                            color: filter.textColor.withAlpha(180),
                            size: 24,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'آية',
                            style: TextStyle(
                              color: filter.textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              fontFamily: filter.fontFamily,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              filter.name,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
