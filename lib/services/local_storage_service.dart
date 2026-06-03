import 'dart:convert';

import '../models/analysis_result.dart';
import '../models/chat_message.dart';
import '../models/crypto_analysis.dart';
import '../models/portfolio_item.dart';
import '../models/stock_analysis.dart';
import '../models/user_settings.dart';
import 'storage_backend.dart';

class LocalStorageService {
  LocalStorageService({StorageBackend? backend})
    : _backend = backend ?? StorageBackend();

  static const _historyKey = 'analysis_history';
  static const _portfolioKey = 'portfolio_items';
  static const _chatKey = 'chat_history';
  static const _settingsKey = 'user_settings';

  final StorageBackend _backend;

  Future<void> saveAnalyses(List<AnalysisResult> analyses) async {
    final payload = analyses.map((item) => item.toJson()).toList();
    await _backend.write(_historyKey, jsonEncode(payload));
  }

  Future<List<AnalysisResult>> loadAnalyses() async {
    final raw = await _backend.read(_historyKey);
    if (raw == null) return [];

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.map((item) {
      final json = item as Map<String, dynamic>;
      if (json['type'] == 'crypto') return CryptoAnalysis.fromJson(json);
      return StockAnalysis.fromJson(json);
    }).toList();
  }

  Future<void> clearAnalyses() => _backend.remove(_historyKey);

  Future<void> savePortfolio(List<PortfolioItem> items) async {
    await _backend.write(
      _portfolioKey,
      jsonEncode(items.map((item) => item.toJson()).toList()),
    );
  }

  Future<List<PortfolioItem>> loadPortfolio() async {
    final raw = await _backend.read(_portfolioKey);
    if (raw == null) return [];

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => PortfolioItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> clearPortfolio() => _backend.remove(_portfolioKey);

  Future<void> saveChat(List<ChatMessage> messages) async {
    await _backend.write(
      _chatKey,
      jsonEncode(messages.map((item) => item.toJson()).toList()),
    );
  }

  Future<List<ChatMessage>> loadChat() async {
    final raw = await _backend.read(_chatKey);
    if (raw == null) return [];

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => ChatMessage.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> clearChat() => _backend.remove(_chatKey);

  Future<void> saveSettings(UserSettings settings) async {
    await _backend.write(_settingsKey, jsonEncode(settings.toJson()));
  }

  Future<UserSettings> loadSettings() async {
    final raw = await _backend.read(_settingsKey);
    if (raw == null) return UserSettings.defaults;

    return UserSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }
}
