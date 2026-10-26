import 'package:flutter/material.dart';
import '../../theme/theme.dart';

class AcousticQuote extends StatelessWidget {
  const AcousticQuote({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(
        children: [
          // Frequency visualiser bars
          SizedBox(
            height: 24,
            child: Opacity(
              opacity: 0.5,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: const [
                  _FrequencyBar(height: 8),
                  SizedBox(width: 6),
                  _FrequencyBar(height: 12),
                  SizedBox(width: 6),
                  _FrequencyBar(height: 20),
                  SizedBox(width: 6),
                  _FrequencyBar(height: 10),
                  SizedBox(width: 6),
                  _FrequencyBar(height: 24),
                  SizedBox(width: 6),
                  _FrequencyBar(height: 16),
                  SizedBox(width: 6),
                  _FrequencyBar(height: 8),
                  SizedBox(width: 6),
                  _FrequencyBar(height: 14),
                  SizedBox(width: 6),
                  _FrequencyBar(height: 6),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '"Silence is not the absence of sound,\nbut the beginning of listening."',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant)
                .copyWith(
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w300,
                ),
          ),
        ],
      ),
    );
  }
}

class _FrequencyBar extends StatelessWidget {
  final double height;
  const _FrequencyBar({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 2,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.secondaryAccent,
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }
}
