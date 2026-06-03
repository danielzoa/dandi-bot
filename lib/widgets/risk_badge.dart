import 'package:flutter/material.dart';

import '../enums/risk_level.dart';

class RiskBadge extends StatelessWidget {
  const RiskBadge({super.key, required this.riskLevel});

  final RiskLevel riskLevel;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: riskLevel.color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: riskLevel.color.withValues(alpha: 0.50)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          riskLevel.label,
          style: TextStyle(
            color: riskLevel.color,
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}
