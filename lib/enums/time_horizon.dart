enum TimeHorizon { shortTerm, mediumTerm, longTerm }

extension TimeHorizonX on TimeHorizon {
  String get label => switch (this) {
    TimeHorizon.shortTerm => 'Curto prazo',
    TimeHorizon.mediumTerm => 'Médio prazo',
    TimeHorizon.longTerm => 'Longo prazo',
  };
}
