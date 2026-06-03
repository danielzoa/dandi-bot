enum AgentRole {
  fundamentalsAnalyst,
  sentimentAnalyst,
  newsAnalyst,
  technicalAnalyst,
  bullResearcher,
  bearResearcher,
  riskManager,
  trader,
}

extension AgentRoleX on AgentRole {
  String get label => switch (this) {
    AgentRole.fundamentalsAnalyst => 'Analista Fundamentalista',
    AgentRole.sentimentAnalyst => 'Analista de Sentimento',
    AgentRole.newsAnalyst => 'Analista de Notícias',
    AgentRole.technicalAnalyst => 'Analista Técnico',
    AgentRole.bullResearcher => 'Agente Bull',
    AgentRole.bearResearcher => 'Agente Bear',
    AgentRole.riskManager => 'Gestor de Risco',
    AgentRole.trader => 'Dandi Bot',
  };

  String get emoji => switch (this) {
    AgentRole.fundamentalsAnalyst => '📋',
    AgentRole.sentimentAnalyst => '💬',
    AgentRole.newsAnalyst => '📰',
    AgentRole.technicalAnalyst => '📈',
    AgentRole.bullResearcher => '🐂',
    AgentRole.bearResearcher => '🐻',
    AgentRole.riskManager => '🛡️',
    AgentRole.trader => '🤖',
  };
}
