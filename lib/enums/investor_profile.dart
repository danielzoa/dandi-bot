enum InvestorProfile { conservative, moderate, aggressive }

extension InvestorProfileX on InvestorProfile {
  String get label => switch (this) {
    InvestorProfile.conservative => 'Conservador',
    InvestorProfile.moderate => 'Moderado',
    InvestorProfile.aggressive => 'Agressivo',
  };
}
