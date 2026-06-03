import 'package:flutter/material.dart';

enum RiskLevel { low, medium, high, extreme }

extension RiskLevelX on RiskLevel {
  String get label => switch (this) {
    RiskLevel.low => 'Baixo',
    RiskLevel.medium => 'Médio',
    RiskLevel.high => 'Alto',
    RiskLevel.extreme => 'Extremo',
  };

  Color get color => switch (this) {
    RiskLevel.low => const Color(0xFF00D4AA),
    RiskLevel.medium => const Color(0xFFF5C842),
    RiskLevel.high => const Color(0xFFE05252),
    RiskLevel.extreme => const Color(0xFFFF3B30),
  };
}
