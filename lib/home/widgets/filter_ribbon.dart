import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/home_bloc.dart';
import '../../theme/theme.dart';

class FilterRibbon extends StatelessWidget {
  const FilterRibbon({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: BlocBuilder<FilterBloc, FilterState>(
        builder: (context, state) {
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            itemCount: state.filters.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final filter = state.filters[i];
              final isActive = filter == state.selectedFilter;
              return GestureDetector(
                onTap: () =>
                    context.read<FilterBloc>().add(FilterSelected(filter)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.primaryText
                        : AppColors.surfaceContainerHigh.withValues(alpha: 0.7),
                    borderRadius: AppRadii.radiusFull,
                  ),
                  child: Text(
                    filter.toUpperCase(),
                    style: AppTypography.labelSm(
                      color: isActive
                          ? AppColors.neutralCanvas
                          : AppColors.onSurfaceVariant,
                    ).copyWith(letterSpacing: 0.08 * 10, fontSize: 10),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
