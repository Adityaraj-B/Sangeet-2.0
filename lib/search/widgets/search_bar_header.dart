import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../theme/theme.dart';
import '../bloc/search_bloc.dart';

class SearchBarHeader extends StatefulWidget {
  final SearchState state;

  const SearchBarHeader({super.key, required this.state});

  @override
  State<SearchBarHeader> createState() => _SearchBarHeaderState();
}

class _SearchBarHeaderState extends State<SearchBarHeader> {
  late final TextEditingController _controller;
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.state.query);
  }

  @override
  void didUpdateWidget(covariant SearchBarHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state.query != _controller.text) {
      _controller.text = widget.state.query;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Editorial Sub-brand / Status Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.secondary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'SEARCH',
                  style: AppTypography.labelSm(
                    color: AppColors.onSurfaceVariant,
                  ).copyWith(letterSpacing: 2.0, fontSize: 10),
                ),
              ],
            ),
            Text(
              'SONGS, ARTISTS & ALBUMS',
              style: AppTypography.labelSm(
                color: AppColors.secondary.withValues(alpha: 0.8),
              ).copyWith(letterSpacing: 1.5, fontSize: 10),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Search Input Bar
        Focus(
          onFocusChange: (focus) => setState(() => _hasFocus = focus),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: _hasFocus
                  ? AppColors.surfaceContainer
                  : AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _hasFocus
                    ? AppColors.secondary.withValues(alpha: 0.35)
                    : AppColors.outlineVariant.withValues(alpha: 0.14),
                width: 1,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.search_rounded,
                  size: 20,
                  color: AppColors.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.search,
                    onChanged: (val) {
                      context.read<SearchBloc>().add(SearchQueryChanged(val));
                    },
                    onSubmitted: (val) {
                      if (val.trim().isNotEmpty) {
                        context.read<SearchBloc>().add(SearchPerformSearch(val));
                      }
                    },
                    style: AppTypography.bodySm(
                      color: AppColors.onSurface,
                    ).copyWith(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search songs, artists, albums...',
                      hintStyle: AppTypography.bodySm(
                        color: AppColors.onSurfaceVariant.withValues(
                          alpha: 0.5,
                        ),
                      ).copyWith(fontSize: 13.5),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                if (state.isSearching)
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: AppColors.onSurfaceVariant,
                    ),
                    onPressed: () {
                      _controller.clear();
                      context.read<SearchBloc>().add(
                        const SearchQueryCleared(),
                      );
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                const SizedBox(width: 6),
                // Acoustic voice / waveform search button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: AppColors.surfaceContainerHigh,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          content: Text(
                            'Acoustic voice search listening for frequencies...',
                            style: AppTypography.bodySm(
                              color: AppColors.primaryText,
                            ),
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.graphic_eq_rounded,
                        size: 20,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
