import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/formatters.dart';

class ConfidenceRing extends StatelessWidget {
  const ConfidenceRing({super.key, required this.confidence, this.size = 92});

  final double confidence;
  final double size;

  @override
  Widget build(BuildContext context) {
    final normalized = confidence.clamp(0.0, 1.0).toDouble();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: normalized),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return CircularProgressIndicator(
                    value: value,
                    strokeWidth: 8,
                    backgroundColor: AppColors.surfaceAlt,
                    color: AppColors.teal,
                    strokeCap: StrokeCap.round,
                  );
                },
              ),
              Text(
                Formatters.confidence(normalized),
                style: AppTextStyles.title.copyWith(fontSize: 21),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Confiança',
          textAlign: TextAlign.center,
          style: AppTextStyles.muted,
        ),
      ],
    );
  }
}
