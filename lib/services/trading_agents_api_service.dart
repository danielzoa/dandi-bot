import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service that communicates with the TradingAgents FastAPI backend
/// (api_server.py running on :8000).
///
/// Provides: health check, chat, analysis, job polling, diagnostics.
class TradingAgentsApiService {
  TradingAgentsApiService({String? baseUrl})
    : _baseUrl = baseUrl ?? 'http://127.0.0.1:8000';

  String _baseUrl;

  String get baseUrl => _baseUrl;
  set baseUrl(String url) {
    // Normalize: remove trailing slash
    _baseUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  // ---------------------------------------------------------------------------
  // Health
  // ---------------------------------------------------------------------------

  /// Returns true if the backend is reachable and healthy.
  Future<bool> isAvailable() async {
    try {
      final health = await healthCheck();
      return health['status'] == 'ok';
    } catch (_) {
      return false;
    }
  }

  /// GET /api/health
  Future<Map<String, dynamic>> healthCheck() async {
    final response = await http
        .get(Uri.parse('$_baseUrl/api/health'))
        .timeout(const Duration(seconds: 5));
    if (response.statusCode != 200) {
      throw Exception('Health check failed: ${response.statusCode}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // ---------------------------------------------------------------------------
  // Chat
  // ---------------------------------------------------------------------------

  /// POST /api/chat — sends a free-form message.
  /// Returns the initial response with possible job_id for tracking.
  Future<Map<String, dynamic>> sendChatMessage({
    required String message,
    String? apiKey,
    String llmProvider = 'google',
    String deepThinkLlm = 'gemini-2.5-pro',
    String quickThinkLlm = 'gemini-2.0-flash',
    int maxDebateRounds = 1,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/api/chat'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'message': message,
            'llm_provider': llmProvider,
            'deep_think_llm': deepThinkLlm,
            'quick_think_llm': quickThinkLlm,
            'max_debate_rounds': maxDebateRounds,
            if (apiKey != null && apiKey.isNotEmpty) 'api_key': apiKey,
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Chat failed: ${response.statusCode} ${response.body}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // ---------------------------------------------------------------------------
  // Analysis
  // ---------------------------------------------------------------------------

  /// POST /api/analyze — starts a background analysis job.
  Future<Map<String, dynamic>> startAnalysis({
    required String ticker,
    required String date,
    String? apiKey,
    String llmProvider = 'google',
    String deepThinkLlm = 'gemini-2.5-pro',
    String quickThinkLlm = 'gemini-2.0-flash',
    int maxDebateRounds = 1,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/api/analyze'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'ticker': ticker,
            'date': date,
            'llm_provider': llmProvider,
            'deep_think_llm': deepThinkLlm,
            'quick_think_llm': quickThinkLlm,
            'max_debate_rounds': maxDebateRounds,
            if (apiKey != null && apiKey.isNotEmpty) 'api_key': apiKey,
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception(
        'Analysis start failed: ${response.statusCode} ${response.body}',
      );
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // ---------------------------------------------------------------------------
  // Job polling
  // ---------------------------------------------------------------------------

  /// GET /api/status/{jobId} — polls the current job state.
  Future<Map<String, dynamic>> pollJobStatus(String jobId) async {
    final response = await http
        .get(Uri.parse('$_baseUrl/api/status/$jobId'))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 404) {
      throw Exception('Job not found: $jobId');
    }
    if (response.statusCode != 200) {
      throw Exception('Status poll failed: ${response.statusCode}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Polls a job until it reaches 'done' or 'error' state.
  /// Returns the final job status map.
  Future<Map<String, dynamic>> waitForJob(
    String jobId, {
    Duration interval = const Duration(seconds: 3),
    Duration timeout = const Duration(minutes: 10),
    void Function(Map<String, dynamic> status)? onProgress,
  }) async {
    final deadline = DateTime.now().add(timeout);

    while (DateTime.now().isBefore(deadline)) {
      final status = await pollJobStatus(jobId);
      final state = status['status'] as String?;

      onProgress?.call(status);

      if (state == 'done' || state == 'error') {
        return status;
      }

      await Future<void>.delayed(interval);
    }

    throw TimeoutException('Job $jobId timed out after $timeout');
  }

  // ---------------------------------------------------------------------------
  // Providers & Diagnostics
  // ---------------------------------------------------------------------------

  /// GET /api/providers
  Future<List<Map<String, dynamic>>> getProviders() async {
    final response = await http
        .get(Uri.parse('$_baseUrl/api/providers'))
        .timeout(const Duration(seconds: 5));
    if (response.statusCode != 200) {
      throw Exception('Providers fetch failed: ${response.statusCode}');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final providers = data['providers'] as List<dynamic>;
    return providers.cast<Map<String, dynamic>>();
  }

  /// GET /api/diagnostics
  Future<Map<String, dynamic>> getDiagnostics() async {
    final response = await http
        .get(Uri.parse('$_baseUrl/api/diagnostics'))
        .timeout(const Duration(seconds: 5));
    if (response.statusCode != 200) {
      throw Exception('Diagnostics failed: ${response.statusCode}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Returns whether the backend has an API key configured for [provider].
  Future<bool> hasConfiguredProvider(String provider) async {
    try {
      final diagnostics = await getDiagnostics();
      final configured = diagnostics['providers_configured'] as List<dynamic>?;
      return configured?.contains(provider) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// GET /api/jobs
  Future<List<Map<String, dynamic>>> listJobs({int limit = 20}) async {
    final response = await http
        .get(Uri.parse('$_baseUrl/api/jobs?limit=$limit'))
        .timeout(const Duration(seconds: 5));
    if (response.statusCode != 200) {
      throw Exception('Jobs list failed: ${response.statusCode}');
    }
    final data = jsonDecode(response.body) as List<dynamic>;
    return data.cast<Map<String, dynamic>>();
  }
}
