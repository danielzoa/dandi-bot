import 'dart:io';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../enums/ai_provider.dart';
import '../enums/market_type.dart';
import '../mock/mock_assets.dart';
import '../models/analysis_result.dart';
import '../models/asset.dart';
import '../models/chat_message.dart';
import '../models/portfolio_item.dart';
import '../models/user_settings.dart';
import '../utils/ticker_detector.dart';
import 'ai_gateway_service.dart';
import 'local_storage_service.dart';
import 'market_catalog_service.dart';
import 'market_quote_service.dart';
import 'mock_analysis_service.dart';
import 'mock_chat_service.dart';
import 'portfolio_service.dart';
import 'trading_agents_api_service.dart';

class AppController extends ChangeNotifier {
  AppController({
    LocalStorageService? localStorageService,
    MockAnalysisService? mockAnalysisService,
    MarketQuoteService? marketQuoteService,
    MarketCatalogService? marketCatalogService,
    AiGatewayService? aiGatewayService,
  }) : storage = localStorageService ?? LocalStorageService(),
       analysisService = mockAnalysisService ?? MockAnalysisService(),
       quoteService = marketQuoteService ?? MarketQuoteService(),
       catalogService = marketCatalogService ?? MarketCatalogService(),
       gatewayService = aiGatewayService ?? MockAiGatewayService() {
    portfolioService = PortfolioService(storage);
    tradingAgentsApi = TradingAgentsApiService();
    chatService = MockChatService(gatewayService, backendApi: tradingAgentsApi);
  }

  final LocalStorageService storage;
  final MockAnalysisService analysisService;
  final MarketQuoteService quoteService;
  final MarketCatalogService catalogService;
  final AiGatewayService gatewayService;
  late final PortfolioService portfolioService;
  late final TradingAgentsApiService tradingAgentsApi;
  late final MockChatService chatService;
  final _uuid = const Uuid();
  bool isBackendOnline = false;

  List<AnalysisResult> analysisHistory = [];
  List<PortfolioItem> portfolioItems = [];
  List<ChatMessage> chatMessages = [];
  UserSettings settings = UserSettings.defaults;
  AnalysisResult? selectedAnalysis;
  final Map<String, Asset> _liveAssets = {};
  final Map<String, Asset> _catalogAssets = {};
  bool isLoadingAnalysis = false;
  bool isRefreshingQuotes = false;
  bool isChatTyping = false;

  Future<void> initialize() async {
    analysisHistory = await storage.loadAnalyses();
    portfolioItems = await storage.loadPortfolio();
    chatMessages = await storage.loadChat();
    settings = await storage.loadSettings();
    if (analysisHistory.isNotEmpty) {
      selectedAnalysis = analysisHistory.first;
    }
    // Sync backend URL from saved settings
    tradingAgentsApi.baseUrl = settings.backendUrl;
    // Check backend health in background (non-blocking)
    checkBackendHealth();
  }

  Future<AnalysisResult> analyzeTicker(String ticker) async {
    final normalized = TickerDetector.normalize(ticker);
    isLoadingAnalysis = true;
    notifyListeners();

    final asset = await _assetWithLatestQuote(normalized);
    return _analyzeAssetWithQuote(asset);
  }

  Future<AnalysisResult> analyzeAsset(Asset asset) async {
    isLoadingAnalysis = true;
    notifyListeners();

    final updatedAsset = await quoteService.enrichAsset(asset);
    _cacheAssets([updatedAsset], notify: false);
    return _analyzeAssetWithQuote(updatedAsset);
  }

  Future<AnalysisResult> _analyzeAssetWithQuote(Asset asset) async {
    final result = await analysisService.analyze(
      asset.ticker,
      asset: asset,
      apiKey: settings.geminiApiKey,
    );
    selectedAnalysis = result;
    analysisHistory = [
      result,
      ...analysisHistory.where(
        (item) => item.asset.ticker != result.asset.ticker,
      ),
    ].take(30).toList();
    await storage.saveAnalyses(analysisHistory);

    isLoadingAnalysis = false;
    notifyListeners();
    return result;
  }

  Future<List<Asset>> searchAssets(
    String query, {
    MarketType? preferredMarket,
    int limit = 12,
  }) async {
    final trimmed = query.trim();
    final localMatches = _rankedLocalAssets(
      trimmed,
      preferredMarket,
    ).take(limit).toList();
    if (trimmed.length < 2) return localMatches;

    final markets = preferredMarket == null
        ? MarketType.values
        : [preferredMarket];
    final pages = await Future.wait(
      markets.map(
        (market) =>
            catalogService.fetchAssets(market, size: limit, query: trimmed),
      ),
    );
    final remoteAssets = pages.expand((page) => page.assets).toList();
    _cacheAssets(remoteAssets, notify: false);

    return _mergeAssets([
      ...localMatches,
      ...remoteAssets,
    ]).take(limit).toList();
  }

  void rememberCatalogAssets(Iterable<Asset> assets) {
    _cacheAssets(assets);
  }

  Future<void> refreshSelectedQuote() async {
    final analysis = selectedAnalysis;
    if (analysis == null || isRefreshingQuotes) return;

    isRefreshingQuotes = true;
    notifyListeners();

    try {
      final asset = await quoteService.enrichAsset(analysis.asset);
      _liveAssets[asset.ticker] = asset;
      selectedAnalysis = analysis.copyWithAsset(asset);
    } finally {
      isRefreshingQuotes = false;
      notifyListeners();
    }
  }

  Future<void> refreshQuotesForAssets(Iterable<Asset> assets) async {
    if (isRefreshingQuotes) return;

    isRefreshingQuotes = true;
    notifyListeners();

    try {
      final updated = await quoteService.enrichAssets(assets);
      for (final asset in updated) {
        _liveAssets[asset.ticker] = asset;
      }
    } finally {
      isRefreshingQuotes = false;
      notifyListeners();
    }
  }

  Future<void> addPortfolioItem({
    required String ticker,
    required double quantity,
    required double entryPrice,
    String? note,
  }) async {
    final normalized = TickerDetector.normalize(ticker);
    final asset = await _assetWithLatestQuote(normalized);
    final analysis = await analysisService.analyze(
      asset.ticker,
      asset: asset,
      apiKey: settings.geminiApiKey,
    );
    final analyzedAsset = analysis.asset;
    final item = PortfolioItem(
      id: _uuid.v4(),
      asset: analyzedAsset,
      quantity: quantity,
      entryPrice: entryPrice,
      currentSimulatedPrice: analyzedAsset.simulatedPrice,
      note: note?.trim().isEmpty ?? true ? null : note!.trim(),
      createdAt: DateTime.now(),
    );

    portfolioItems = [...portfolioItems, item];
    await storage.savePortfolio(portfolioItems);
    notifyListeners();
  }

  Future<void> addAssetToPortfolio(Asset asset) async {
    final updatedAsset = await quoteService.enrichAsset(asset);
    _liveAssets[updatedAsset.ticker] = updatedAsset;
    final item = PortfolioItem(
      id: _uuid.v4(),
      asset: updatedAsset,
      quantity: 1,
      entryPrice: updatedAsset.simulatedPrice,
      currentSimulatedPrice: updatedAsset.simulatedPrice,
      note: 'Adicionado pela análise simulada.',
      createdAt: DateTime.now(),
    );
    portfolioItems = [...portfolioItems, item];
    await storage.savePortfolio(portfolioItems);
    notifyListeners();
  }

  Future<void> removePortfolioItem(String id) async {
    portfolioItems = portfolioItems.where((item) => item.id != id).toList();
    await storage.savePortfolio(portfolioItems);
    notifyListeners();
  }

  Future<void> sendChatMessage(String content) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return;

    final contextTicker =
        selectedAnalysis?.asset.ticker ?? _extractTicker(trimmed);
    final userMessage = ChatMessage(
      id: _uuid.v4(),
      content: trimmed,
      sender: MessageSender.user,
      createdAt: DateTime.now(),
      relatedTicker: contextTicker,
    );

    chatMessages = [...chatMessages, userMessage];
    isChatTyping = true;
    notifyListeners();
    await storage.saveChat(chatMessages);

    final botMessage = await chatService.sendMessage(
      trimmed,
      contextTicker: contextTicker,
      history: chatMessages.reversed.take(10).toList().reversed.toList(),
      apiKey: settings.geminiApiKey,
    );

    chatMessages = [...chatMessages, botMessage];
    isChatTyping = false;
    await _syncAgentsDebateFromChat(botMessage, apiKey: settings.geminiApiKey);
    await storage.saveChat(chatMessages);
    notifyListeners();
  }

  Future<void> updateSettings(UserSettings next) async {
    settings = next;
    await storage.saveSettings(settings);
    // Sync backend URL if changed
    tradingAgentsApi.baseUrl = settings.backendUrl;
    notifyListeners();
  }

  bool _isSpawningBackend = false;

  /// Check if the TradingAgents backend is reachable.
  Future<bool> checkBackendHealth() async {
    try {
      isBackendOnline = await tradingAgentsApi.isAvailable();
    } catch (_) {
      isBackendOnline = false;
    }
    if (!isBackendOnline &&
        !_isSpawningBackend &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      _spawnBackend();
    }

    notifyListeners();
    return isBackendOnline;
  }

  Future<void> _spawnBackend() async {
    _isSpawningBackend = true;
    try {
      debugPrint('[AppController] Attempting to auto-start backend...');
      final projectRoot = _findProjectRoot();
      if (Platform.isWindows) {
        await Process.start(
          'cmd',
          ['/c', 'start', '/min', 'SETUP_BACKEND.bat'],
          runInShell: true,
          workingDirectory: projectRoot,
        );
      } else {
        await Process.start(
          'sh',
          ['./SETUP_BACKEND.sh'],
          runInShell: true,
          workingDirectory: projectRoot,
        );
      }

      // Try polling a few times to see if it comes online
      for (int i = 0; i < 6; i++) {
        await Future.delayed(const Duration(seconds: 5));
        final isOnline = await tradingAgentsApi.isAvailable();
        if (isOnline) {
          isBackendOnline = true;
          notifyListeners();
          break;
        }
      }
    } catch (e) {
      debugPrint('[AppController] Auto-start backend failed: $e');
    } finally {
      _isSpawningBackend = false;
    }
  }

  Future<void> _syncAgentsDebateFromChat(
    ChatMessage botMessage, {
    String? apiKey,
  }) async {
    final ticker = botMessage.relatedTicker;
    if (botMessage.provider != AiProvider.tradingAgents ||
        ticker == null ||
        ticker.trim().isEmpty) {
      return;
    }

    try {
      final asset = await _assetWithLatestQuote(ticker);
      final result = await analysisService.analyze(
        asset.ticker,
        asset: asset,
        apiKey: apiKey,
      );
      selectedAnalysis = result;
      analysisHistory = [
        result,
        ...analysisHistory.where(
          (item) => item.asset.ticker != result.asset.ticker,
        ),
      ].take(30).toList();
      await storage.saveAnalyses(analysisHistory);
    } catch (e) {
      debugPrint('[AppController] Failed to sync agents debate from chat: $e');
    }
  }

  String _findProjectRoot() {
    var dir = Directory.current;
    for (var i = 0; i < 8; i++) {
      if (File(
        '${dir.path}${Platform.pathSeparator}SETUP_BACKEND.bat',
      ).existsSync()) {
        return dir.path;
      }
      final parent = dir.parent;
      if (parent.path == dir.path) break;
      dir = parent;
    }

    final executableDir = File(Platform.resolvedExecutable).parent;
    dir = executableDir;
    for (var i = 0; i < 8; i++) {
      if (File(
        '${dir.path}${Platform.pathSeparator}SETUP_BACKEND.bat',
      ).existsSync()) {
        return dir.path;
      }
      final parent = dir.parent;
      if (parent.path == dir.path) break;
      dir = parent;
    }

    return Directory.current.path;
  }

  Future<void> clearAnalysisHistory() async {
    analysisHistory = [];
    selectedAnalysis = null;
    await storage.clearAnalyses();
    notifyListeners();
  }

  Future<void> clearPortfolio() async {
    portfolioItems = [];
    await storage.clearPortfolio();
    notifyListeners();
  }

  Future<void> clearChat() async {
    chatMessages = [];
    await storage.clearChat();
    notifyListeners();
  }

  Asset assetForTicker(String ticker) {
    final asset = MockAssets.find(ticker) ?? MockAssets.generic(ticker);
    return _liveAssets[asset.ticker] ?? _catalogAssets[asset.ticker] ?? asset;
  }

  List<Asset> assetsByMarket(MarketType marketType) {
    return _mergeAssets([
      ...MockAssets.byMarket(marketType),
      ..._catalogAssets.values.where((asset) => asset.marketType == marketType),
    ]).map((asset) => _liveAssets[asset.ticker] ?? asset).toList();
  }

  List<Asset> get availableAssets {
    return _mergeAssets([
      ...MockAssets.all,
      ..._catalogAssets.values,
    ]).map((asset) => _liveAssets[asset.ticker] ?? asset).toList();
  }

  Future<Asset> _assetWithLatestQuote(String ticker) async {
    final normalized = TickerDetector.normalize(ticker);
    final base =
        _catalogAssets[normalized] ??
        MockAssets.find(normalized) ??
        MockAssets.generic(normalized);
    final updated = await quoteService.enrichAsset(base);
    _cacheAssets([updated], notify: false);
    return updated;
  }

  List<Asset> _rankedLocalAssets(String query, MarketType? preferredMarket) {
    final normalizedQuery = _normalizeSearch(query);
    final matches = availableAssets.where((asset) {
      if (preferredMarket != null && asset.marketType != preferredMarket) {
        return false;
      }
      if (normalizedQuery.isEmpty) return true;
      final haystack = _normalizeSearch(
        '${asset.ticker} ${asset.name} '
        '${asset.marketType.label} ${asset.marketType.shortLabel}',
      );
      return normalizedQuery.split(' ').every(haystack.contains);
    }).toList();

    matches.sort((a, b) {
      final rank = _rankAsset(
        a,
        normalizedQuery,
      ).compareTo(_rankAsset(b, normalizedQuery));
      if (rank != 0) return rank;
      return a.ticker.compareTo(b.ticker);
    });
    return matches;
  }

  int _rankAsset(Asset asset, String query) {
    if (query.isEmpty) return 0;

    final ticker = _normalizeSearch(asset.ticker);
    final name = _normalizeSearch(asset.name);

    if (ticker == query) return 0;
    if (ticker.startsWith(query)) return 1;
    if (name.startsWith(query)) return 2;
    if (ticker.contains(query)) return 3;
    if (name.contains(query)) return 4;
    return 5;
  }

  List<Asset> _mergeAssets(Iterable<Asset> assets) {
    final merged = <String, Asset>{};
    for (final asset in assets) {
      final live = _liveAssets[asset.ticker];
      merged[asset.ticker] = live ?? asset;
    }
    return merged.values.toList();
  }

  void _cacheAssets(Iterable<Asset> assets, {bool notify = true}) {
    for (final asset in assets) {
      _catalogAssets[asset.ticker] = asset;
      if (asset.quoteIsLive) _liveAssets[asset.ticker] = asset;
    }
    if (notify) notifyListeners();
  }

  String _normalizeSearch(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('â', 'a')
        .replaceAll('é', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ç', 'c');
  }

  String? _extractTicker(String message) {
    final regex = RegExp(r'\b[A-Z]{3,6}(?:\.SA|-USD)?\b', caseSensitive: false);
    return regex.firstMatch(message.toUpperCase())?.group(0);
  }
}

class DandiScope extends InheritedNotifier<AppController> {
  const DandiScope({
    super.key,
    required AppController controller,
    required super.child,
  }) : super(notifier: controller);

  static AppController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<DandiScope>();
    assert(scope != null, 'DandiScope not found in context.');
    return scope!.notifier!;
  }
}
