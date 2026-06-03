import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class SuggestionChipRow extends StatelessWidget {
  const SuggestionChipRow({
    super.key,
    required this.suggestions,
    required this.onSelected,
  });

  final List<String> suggestions;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final suggestion in suggestions) ...[
            ActionChip(
              label: Text(suggestion),
              side: BorderSide(color: AppColors.border.withValues(alpha: 0.9)),
              backgroundColor: AppColors.surface,
              onPressed: () => onSelected(suggestion),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}
