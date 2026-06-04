import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'enums/market_type.dart';
import 'screens/agents/agents_debate_screen.dart';
import 'screens/analysis/analysis_screen.dart';
import 'screens/chat/chat_screen.dart';
import 'screens/history/history_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/markets/market_catalog_screen.dart';
import 'screens/markets/markets_screen.dart';
import 'screens/news/news_screen.dart';
import 'screens/portfolio/portfolio_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'services/app_controller.dart';
import 'theme/app_theme.dart';
import 'widgets/app_shell.dart';

const routeHome = '/';
const routeMarkets = '/markets';
const routeAnalysis = '/analysis';
const routeAgents = '/agents';
const routePortfolio = '/portfolio';
const routeHistory = '/history';
const routeChat = '/chat';
const routeNews = '/news';
const routeSettings = '/settings';
const routeMarketCatalog = '/markets/catalog';

class DandiApp extends StatelessWidget {
  DandiApp({super.key, required this.controller});

  final AppController controller;

  late final GoRouter _router = GoRouter(
    routes: [
      _route(routeHome, (_) => const HomeScreen()),
      _route(routeMarkets, (_) => const MarketsScreen()),
      _route(routeMarketCatalog, (state) {
        final marketName = state.uri.queryParameters['market'];
        final marketType = MarketType.values.firstWhere(
          (market) => market.name == marketName,
          orElse: () => MarketType.brazil,
        );
        return MarketCatalogScreen(
          key: ValueKey(marketType),
          marketType: marketType,
        );
      }),
      _route(
        routeAnalysis,
        (state) =>
            AnalysisScreen(initialTicker: state.uri.queryParameters['ticker']),
      ),
      _route(routeAgents, (_) => const AgentsDebateScreen()),
      _route(routePortfolio, (_) => const PortfolioScreen()),
      _route(routeHistory, (_) => const HistoryScreen()),
      _route(routeChat, (_) => const ChatScreen()),
      _route(routeNews, (_) => const NewsScreen()),
      _route(routeSettings, (_) => const SettingsScreen()),
    ],
  );

  static GoRoute _route(
    String path,
    Widget Function(GoRouterState state) childBuilder,
  ) {
    return GoRoute(
      path: path,
      pageBuilder: (context, state) {
        return CustomTransitionPage<void>(
          key: state.pageKey,
          child: AppShell(child: childBuilder(state)),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DandiScope(
      controller: controller,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return MaterialApp.router(
            title: 'Dandi Bot',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.dark(),
            darkTheme: AppTheme.dark(),
            themeMode: controller.settings.themeMode,
            routerConfig: _router,
          );
        },
      ),
    );
  }
}
