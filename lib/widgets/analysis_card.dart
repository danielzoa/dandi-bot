import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class DandiCard extends StatelessWidget {
  const DandiCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.highlight = false,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool highlight;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = DecoratedBox(
      decoration: BoxDecoration(
        color: highlight
            ? AppColors.surfaceAlt.withValues(alpha: 0.68)
            : AppColors.surface.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: highlight ? AppColors.borderActive : AppColors.border,
          width: highlight ? 1.2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: highlight
                ? AppColors.blueBright.withValues(alpha: 0.10)
                : AppColors.cardGlow,
            blurRadius: highlight ? 28 : 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );

    if (onTap == null) return card;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: card,
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: AppTextStyles.subtitle)),
        ?trailing,
      ],
    );
  }
}

class InfoPill extends StatelessWidget {
  const InfoPill({
    super.key,
    required this.label,
    required this.value,
    this.color = AppColors.blue,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.muted),
            const SizedBox(height: 5),
            Text(value, style: AppTextStyles.mono),
          ],
        ),
      ),
    );
  }
}
