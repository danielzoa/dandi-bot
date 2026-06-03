import 'package:flutter/material.dart';

enum AssetDecision { buy, overweight, hold, underweight, sell }

extension AssetDecisionX on AssetDecision {
  String get label => switch (this) {
    AssetDecision.buy => 'COMPRAR',
    AssetDecision.overweight => 'COMPRAR C/ CAUTELA',
    AssetDecision.hold => 'MANTER',
    AssetDecision.underweight => 'REDUZIR',
    AssetDecision.sell => 'VENDER',
  };

  String get filterLabel => switch (this) {
    AssetDecision.buy => 'Comprar',
    AssetDecision.overweight => 'Overweight',
    AssetDecision.hold => 'Manter',
    AssetDecision.underweight => 'Reduzir',
    AssetDecision.sell => 'Vender',
  };

  Color get color => switch (this) {
    AssetDecision.buy => const Color(0xFF00D4AA),
    AssetDecision.overweight => const Color(0xFF4CAF50),
    AssetDecision.hold => const Color(0xFFF5C842),
    AssetDecision.underweight => const Color(0xFFFF9800),
    AssetDecision.sell => const Color(0xFFE05252),
  };
}
