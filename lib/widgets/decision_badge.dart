import 'package:flutter/material.dart';

import '../enums/asset_decision.dart';

class DecisionBadge extends StatelessWidget {
  const DecisionBadge({super.key, required this.decision});

  final AssetDecision decision;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: decision.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: decision.color.withValues(alpha: 0.55)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          decision.label,
          style: TextStyle(
            color: decision.color,
            fontWeight: FontWeight.w800,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}
