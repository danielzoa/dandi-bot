import 'dart:async';
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../app.dart';
import '../../enums/asset_decision.dart';
import '../../enums/market_type.dart';
import '../../enums/risk_level.dart';
import '../../models/analysis_result.dart';
import '../../services/app_controller.dart';
import '../../services/market_quote_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/formatters.dart';
import '../../widgets/analysis_card.dart';
import '../../widgets/confidence_ring.dart';
import '../../widgets/decision_badge.dart';
import '../../widgets/risk_badge.dart';
import '../../widgets/tradingview_chart_frame.dart';
import '../agents/agents_debate_screen.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key, this.initialTicker});

  final String? initialTicker;

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  String? _loadedTicker;
  Timer? _quoteTimer;
  bool _refreshingQuote = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadIfNeeded();
      _startQuoteTimer();
    });
  }

  @override
  void dispose() {
    _quoteTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant AnalysisScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTicker != oldWidget.initialTicker) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadIfNeeded());
    }
  }

  Future<void> _loadIfNeeded() async {
    final controller = DandiScope.of(context);
    final ticker =
        widget.initialTicker ??
        controller.selectedAnalysis?.asset.ticker ??
        'PETR4.SA';
    if (controller.selectedAnalysis?.asset.ticker == ticker) {
      _loadedTicker = ticker;
      return;
    }
    if (_loadedTicker == ticker && controller.selectedAnalysis != null) return;
    _loadedTicker = ticker;
    await controller.analyzeTicker(ticker);
  }

  void _startQuoteTimer() {
    _quoteTimer ??= Timer.periodic(
      MarketQuoteService.refreshInterval,
      (_) => _refreshSelectedQuote(),
    );
  }

  Future<void> _refreshSelectedQuote() async {
    if (_refreshingQuote || !mounted) return;
    _refreshingQuote = true;
    try {
      await DandiScope.of(context).refreshSelectedQuote();
    } finally {
      _refreshingQuote = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = DandiScope.of(context);
    final analysis = controller.selectedAnalysis;

    if (analysis == null) {
      return const _AnalysisSkeleton();
    }

    return DefaultTabController(
      length: 5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (controller.isLoadingAnalysis)
            const LinearProgressIndicator(minHeight: 2),
          _AnalysisHeader(
            analysis: analysis,
            refreshingQuote: controller.isRefreshingQuotes,
          ),
          const SizedBox(height: 18),
          const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Resumo'),
              Tab(text: 'Análise Completa'),
              Tab(text: 'Debate dos Agentes'),
              Tab(text: 'Gráficos'),
              Tab(text: 'Histórico do Ativo'),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: _tabHeight(context),
            child: TabBarView(
              children: [
                _SummaryTab(analysis: analysis),
                _FullAnalysisTab(analysis: analysis),
                SingleChildScrollView(
                  child: AgentsDebateList(analysis: analysis),
                ),
                _ChartTab(analysis: analysis),
                _AssetHistoryTab(analysis: analysis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _tabHeight(BuildContext context) {
    return 760.0;
  }
}

class _AnalysisHeader extends StatelessWidget {
  const _AnalysisHeader({
    required this.analysis,
    required this.refreshingQuote,
  });

  final AnalysisResult analysis;
  final bool refreshingQuote;

  @override
  Widget build(BuildContext context) {
    final controller = DandiScope.of(context);
    final asset = analysis.asset;
    final changeColor = asset.simulatedChangePercent >= 0
        ? AppColors.teal
        : AppColors.red;

    return DandiCard(
      highlight: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;
          final quoteUpdatedAt = asset.quoteUpdatedAt ?? analysis.createdAt;
          final quoteSource = asset.quoteIsLive
              ? 'Fonte ${asset.quoteSource}'
              : 'Preço simulado';
          final info = Wrap(
            spacing: 16,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                Formatters.compactMoney(asset.simulatedPrice, asset.currency),
                style: AppTextStyles.mono.copyWith(fontSize: 20),
              ),
              Text(
                Formatters.percent(asset.simulatedChangePercent, signed: true),
                style: TextStyle(
                  color: changeColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'Mercado ${asset.marketType.label}',
                style: AppTextStyles.muted,
              ),
              Text(quoteSource, style: AppTextStyles.muted),
              Text(
                refreshingQuote
                    ? 'Atualizando...'
                    : 'Atualizado ${Formatters.time(quoteUpdatedAt)}',
                style: AppTextStyles.muted,
              ),
            ],
          );

          final actions = Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: () => controller.addAssetToPortfolio(asset),
                icon: const Icon(Icons.add_circle_outline_rounded),
                label: const Text('Adicionar à carteira'),
              ),
              OutlinedButton.icon(
                onPressed: () => context.go(routeAgents),
                icon: const Icon(Icons.forum_outlined),
                label: const Text('Ver debate'),
              ),
              OutlinedButton.icon(
                onPressed: () => context.go(routeChat),
                icon: const Icon(Icons.chat_bubble_outline_rounded),
                label: const Text('Perguntar ao chat'),
              ),
            ],
          );

          final identity = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                asset.ticker,
                style: AppTextStyles.display.copyWith(fontSize: 26),
              ),
              Text(
                asset.name,
                style: AppTextStyles.body.copyWith(color: AppColors.muted),
              ),
              const SizedBox(height: 12),
              info,
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [identity, const SizedBox(height: 18), actions],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: identity),
              const SizedBox(width: 18),
              actions,
            ],
          );
        },
      ),
    );
  }
}

class _SummaryTab extends StatelessWidget {
  const _SummaryTab({required this.analysis});

  final AnalysisResult analysis;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth > 980;
          final left = Column(
            children: [
              _DecisionCard(analysis: analysis),
              const SizedBox(height: 14),
              _SignalGrid(analysis: analysis),
              const SizedBox(height: 14),
              _IndicatorsGrid(analysis: analysis),
            ],
          );
          final right = Column(
            children: [
              _TextSummaryCard(analysis: analysis),
              const SizedBox(height: 14),
              _PointsCard(
                title: 'Pontos positivos',
                points: analysis.positivePoints,
                positive: true,
              ),
              const SizedBox(height: 14),
              _PointsCard(
                title: 'Pontos de atenção',
                points: analysis.cautionPoints,
                positive: false,
              ),
            ],
          );

          if (!wide) {
            return Column(children: [left, const SizedBox(height: 14), right]);
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: left),
              const SizedBox(width: 14),
              Expanded(child: right),
            ],
          );
        },
      ),
    );
  }
}

class _DecisionCard extends StatelessWidget {
  const _DecisionCard({required this.analysis});

  final AnalysisResult analysis;

  @override
  Widget build(BuildContext context) {
    return DandiCard(
      highlight: true,
      child: Row(
        children: [
          ConfidenceRing(confidence: analysis.confidence),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Decisão do Dandi Bot', style: AppTextStyles.subtitle),
                const SizedBox(height: 10),
                DecisionBadge(decision: analysis.decision),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text('Nível de risco: ', style: AppTextStyles.muted),
                    RiskBadge(riskLevel: analysis.riskLevel),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Ativo com leitura simulada ${analysis.decision.label.toLowerCase()} e confiança de ${Formatters.confidence(analysis.confidence)}.',
                  style: AppTextStyles.body,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SignalGrid extends StatelessWidget {
  const _SignalGrid({required this.analysis});

  final AnalysisResult analysis;

  @override
  Widget build(BuildContext context) {
    final dividendLabel = analysis.asset.marketType == MarketType.crypto
        ? 'Liquidez'
        : 'Dividendos/JCP';
    final items = [
      ('Técnica', _signalLabel(analysis.decision), analysis.decision.color),
      ('Fundamentos', 'Bom', AppColors.teal),
      (
        dividendLabel,
        analysis.dividendText == null ? 'N/A' : 'Bom',
        AppColors.teal,
      ),
      ('Macro', 'Neutro', AppColors.gold),
      ('Risco Reg.', analysis.riskLevel.label, analysis.riskLevel.color),
      ('Sentimento', 'Neutro', AppColors.gold),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.55,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return InfoPill(label: item.$1, value: item.$2, color: item.$3);
      },
    );
  }

  String _signalLabel(AssetDecision decision) {
    return switch (decision) {
      AssetDecision.buy || AssetDecision.overweight => 'Positiva',
      AssetDecision.hold => 'Neutra',
      AssetDecision.underweight || AssetDecision.sell => 'Fraca',
    };
  }
}

class _IndicatorsGrid extends StatelessWidget {
  const _IndicatorsGrid({required this.analysis});

  final AnalysisResult analysis;

  @override
  Widget build(BuildContext context) {
    return DandiCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(title: 'Indicadores principais'),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth > 620 ? 3 : 2;
              final entries = analysis.indicators.entries.toList();
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: entries.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 2.4,
                ),
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  return InfoPill(label: entry.key, value: entry.value);
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TextSummaryCard extends StatelessWidget {
  const _TextSummaryCard({required this.analysis});

  final AnalysisResult analysis;

  @override
  Widget build(BuildContext context) {
    return DandiCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(title: 'Resumo da análise'),
          const SizedBox(height: 12),
          Text(analysis.summary, style: AppTextStyles.body),
        ],
      ),
    );
  }
}

class _PointsCard extends StatelessWidget {
  const _PointsCard({
    required this.title,
    required this.points,
    required this.positive,
  });

  final String title;
  final List<String> points;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final color = positive ? AppColors.teal : AppColors.red;
    return DandiCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(title: title),
          const SizedBox(height: 12),
          for (final point in points)
            Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    positive
                        ? Icons.check_circle_rounded
                        : Icons.warning_amber_rounded,
                    color: color,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(point, style: AppTextStyles.body)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _FullAnalysisTab extends StatelessWidget {
  const _FullAnalysisTab({required this.analysis});

  final AnalysisResult analysis;

  @override
  Widget build(BuildContext context) {
    final sections = [
      ('Análise técnica', analysis.technicalAnalysis, Icons.show_chart_rounded),
      (
        'Fundamentos / Métricas',
        analysis.fundamentalsText,
        Icons.fact_check_outlined,
      ),
      if (analysis.dividendText != null)
        ('Dividendos/JCP', analysis.dividendText!, Icons.payments_outlined),
      ('Macro', analysis.macroAnalysis, Icons.public_rounded),
      ('Risco regulatório', analysis.regulatoryRisk, Icons.gavel_rounded),
      ('Sentimento', analysis.sentiment, Icons.forum_outlined),
    ];

    return SingleChildScrollView(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth > 860 ? 2 : 1;
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sections.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: columns == 1 ? 3.2 : 2.1,
            ),
            itemBuilder: (context, index) {
              final section = sections[index];
              return DandiCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(section.$3, color: AppColors.blueBright),
                    const SizedBox(height: 10),
                    Text(section.$1, style: AppTextStyles.subtitle),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Text(
                        section.$2,
                        style: AppTextStyles.body,
                        overflow: TextOverflow.fade,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ChartTab extends StatelessWidget {
  const _ChartTab({required this.analysis});

  final AnalysisResult analysis;

  @override
  Widget build(BuildContext context) {
    return _TradingViewChartCard(analysis: analysis);
  }
}

class _TradingViewChartCard extends StatelessWidget {
  const _TradingViewChartCard({required this.analysis});

  final AnalysisResult analysis;

  @override
  Widget build(BuildContext context) {
    return DandiCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(title: 'Gráfico TradingView'),
          const SizedBox(height: 8),
          Text(
            'Fonte visual TradingView para ações, ETFs e criptomoedas.',
            style: AppTextStyles.muted,
          ),
          const SizedBox(height: 18),
          Expanded(child: TradingViewChartFrame(asset: analysis.asset)),
        ],
      ),
    );
  }
}

class _CoinGeckoChartCard extends StatefulWidget {
  const _CoinGeckoChartCard({required this.analysis});

  final AnalysisResult analysis;

  @override
  State<_CoinGeckoChartCard> createState() => _CoinGeckoChartCardState();
}

class _CoinGeckoChartCardState extends State<_CoinGeckoChartCard> {
  MarketQuoteService? _service;
  Future<MarketChart?>? _chartFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final service = DandiScope.of(context).quoteService;
    if (_service != service) {
      _service = service;
      _loadChart();
    }
  }

  @override
  void didUpdateWidget(covariant _CoinGeckoChartCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.analysis.asset.ticker != widget.analysis.asset.ticker) {
      _loadChart();
    }
  }

  void _loadChart() {
    _chartFuture = _service?.fetchCoinGeckoChart(widget.analysis.asset);
  }

  void _refreshChart() {
    setState(_loadChart);
  }

  @override
  Widget build(BuildContext context) {
    final future = _chartFuture;

    return DandiCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: SectionTitle(title: 'Gráfico CoinGecko')),
              IconButton(
                onPressed: _refreshChart,
                tooltip: 'Atualizar gráfico',
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Histórico de preço em USD com dados do CoinGecko.',
            style: AppTextStyles.muted,
          ),
          const SizedBox(height: 18),
          Expanded(
            child: future == null
                ? const Center(child: CircularProgressIndicator())
                : FutureBuilder<MarketChart?>(
                    future: future,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final chart = snapshot.data;
                      if (snapshot.hasError ||
                          chart == null ||
                          chart.points.length < 2) {
                        return const _ChartEmptyState(
                          message:
                              'Não foi possível carregar o histórico do CoinGecko agora.',
                        );
                      }

                      return _CoinGeckoLineChart(
                        chart: chart,
                        analysis: widget.analysis,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _CoinGeckoLineChart extends StatelessWidget {
  const _CoinGeckoLineChart({required this.chart, required this.analysis});

  final MarketChart chart;
  final AnalysisResult analysis;

  @override
  Widget build(BuildContext context) {
    final points = chart.points;
    final firstPrice = points.first.price;
    final lastPrice = points.last.price;
    final periodChange = firstPrice == 0
        ? 0.0
        : ((lastPrice - firstPrice) / firstPrice) * 100;
    final positive = periodChange >= 0;
    final color = positive ? AppColors.teal : AppColors.red;
    final spots = [
      for (var i = 0; i < points.length; i++)
        FlSpot(i.toDouble(), points[i].price),
    ];
    final minPrice = points
        .map((point) => point.price)
        .reduce((a, b) => math.min(a, b));
    final maxPrice = points
        .map((point) => point.price)
        .reduce((a, b) => math.max(a, b));
    final yPadding = math.max((maxPrice - minPrice).abs() * 0.08, 0.01);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            Text(
              'Atual ${Formatters.compactMoney(lastPrice, analysis.asset.currency)}',
              style: AppTextStyles.mono,
            ),
            Text(
              '7 dias ${Formatters.percent(periodChange, signed: true)}',
              style: TextStyle(color: color, fontWeight: FontWeight.w800),
            ),
            Text(
              'Fonte ${chart.source} • ${Formatters.time(chart.fetchedAt)}',
              style: AppTextStyles.muted,
            ),
          ],
        ),
        const SizedBox(height: 14),
        Expanded(
          child: LineChart(
            LineChartData(
              minY: minPrice - yPadding,
              maxY: maxPrice + yPadding,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: AppColors.border.withValues(alpha: 0.7),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(color: AppColors.border),
              ),
              titlesData: FlTitlesData(show: false),
              lineTouchData: LineTouchData(
                handleBuiltInTouches: true,
                touchTooltipData: LineTouchTooltipData(
                  tooltipRoundedRadius: 8,
                  getTooltipItems: (items) {
                    return items.map((item) {
                      final index = item.x.round().clamp(0, points.length - 1);
                      final point = points[index];
                      return LineTooltipItem(
                        '${Formatters.dateTime(point.time)}\n'
                        '${Formatters.compactMoney(point.price, analysis.asset.currency)}',
                        AppTextStyles.mono.copyWith(color: Colors.white),
                      );
                    }).toList();
                  },
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: color,
                  barWidth: 3,
                  dotData: FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: color.withValues(alpha: 0.12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ChartEmptyState extends StatelessWidget {
  const _ChartEmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Text(
            message,
            style: AppTextStyles.muted,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _AssetHistoryTab extends StatelessWidget {
  const _AssetHistoryTab({required this.analysis});

  final AnalysisResult analysis;

  @override
  Widget build(BuildContext context) {
    final controller = DandiScope.of(context);
    final items = controller.analysisHistory
        .where((item) => item.asset.ticker == analysis.asset.ticker)
        .toList();

    return SingleChildScrollView(
      child: Column(
        children: [
          for (final item in items) ...[
            DandiCard(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.asset.ticker, style: AppTextStyles.mono),
                        Text(
                          Formatters.dateTime(item.createdAt),
                          style: AppTextStyles.muted,
                        ),
                      ],
                    ),
                  ),
                  DecisionBadge(decision: item.decision),
                  const SizedBox(width: 8),
                  RiskBadge(riskLevel: item.riskLevel),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _AnalysisSkeleton extends StatelessWidget {
  const _AnalysisSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surface,
      highlightColor: AppColors.surfaceAlt,
      child: Column(
        children: [
          for (var i = 0; i < 4; i++) ...[
            Container(
              height: i == 0 ? 140 : 110,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}
