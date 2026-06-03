import 'package:flutter/material.dart';

import '../../enums/agent_role.dart';
import '../../enums/ai_provider.dart';
import '../../enums/currency.dart';
import '../../enums/investor_profile.dart';
import '../../enums/time_horizon.dart';
import '../../services/ai_gateway_service.dart';
import '../../services/app_controller.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/analysis_card.dart';
import '../../widgets/dandi_bot_avatar.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = DandiScope.of(context);
    final settings = controller.settings;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const DandiBotAvatar(size: 54),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Configurações', style: AppTextStyles.display),
            ),
          ],
        ),
        const SizedBox(height: 18),
        DandiCard(
          child: Column(
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Tema escuro'),
                subtitle: const Text('Visual principal do Dandi Bot'),
                value: settings.themeMode == ThemeMode.dark,
                onChanged: (value) {
                  controller.updateSettings(
                    settings.copyWith(
                      themeMode: value ? ThemeMode.dark : ThemeMode.light,
                    ),
                  );
                },
              ),
              const Divider(),
              _DropdownRow<InvestorProfile>(
                label: 'Perfil de investidor',
                value: settings.investorProfile,
                values: InvestorProfile.values,
                labelFor: (value) => value.label,
                onChanged: (value) => controller.updateSettings(
                  settings.copyWith(investorProfile: value),
                ),
              ),
              const SizedBox(height: 12),
              _DropdownRow<TimeHorizon>(
                label: 'Horizonte',
                value: settings.timeHorizon,
                values: TimeHorizon.values,
                labelFor: (value) => value.label,
                onChanged: (value) => controller.updateSettings(
                  settings.copyWith(timeHorizon: value),
                ),
              ),
              const SizedBox(height: 12),
              _DropdownRow<Currency>(
                label: 'Moeda de referência',
                value: settings.currency,
                values: Currency.values,
                labelFor: (value) => value.label,
                onChanged: (value) => controller.updateSettings(
                  settings.copyWith(currency: value),
                ),
              ),
              const Divider(height: 24),
              _ApiKeyInput(
                initialValue: settings.geminiApiKey,
                onChanged: (value) {
                  controller.updateSettings(
                    settings.copyWith(geminiApiKey: value),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        DandiCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle(title: 'TradingAgents Backend'),
              const SizedBox(height: 12),
              _BackendUrlInput(
                initialValue: settings.backendUrl,
                isOnline: controller.isBackendOnline,
                onChanged: (value) {
                  controller.updateSettings(
                    settings.copyWith(backendUrl: value),
                  );
                },
                onTest: () => controller.checkBackendHealth(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        DandiCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle(title: 'Limpeza de dados locais'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _confirm(
                      context,
                      'Limpar histórico de análises?',
                      controller.clearAnalysisHistory,
                    ),
                    icon: const Icon(Icons.history_rounded),
                    label: const Text('Limpar análises'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _confirm(
                      context,
                      'Limpar carteira simulada?',
                      controller.clearPortfolio,
                    ),
                    icon: const Icon(Icons.account_balance_wallet_outlined),
                    label: const Text('Limpar carteira'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _confirm(
                      context,
                      'Limpar histórico do chat?',
                      controller.clearChat,
                    ),
                    icon: const Icon(Icons.chat_bubble_outline_rounded),
                    label: const Text('Limpar chat'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth > 860;
            final about = _AboutCard();
            final providers = _ProvidersCard();

            if (!wide) {
              return Column(
                children: [about, const SizedBox(height: 14), providers],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: about),
                const SizedBox(width: 14),
                Expanded(child: providers),
              ],
            );
          },
        ),
      ],
    );
  }

  Future<void> _confirm(
    BuildContext context,
    String title,
    Future<void> Function() action,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: const Text(
          'Esta ação remove apenas dados simulados salvos neste app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await action();
    }
  }
}

class _DropdownRow<T> extends StatelessWidget {
  const _DropdownRow({
    required this.label,
    required this.value,
    required this.values,
    required this.labelFor,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> values;
  final String Function(T value) labelFor;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: [
        for (final item in values)
          DropdownMenuItem<T>(value: item, child: Text(labelFor(item))),
      ],
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}

class _AboutCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DandiCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(title: 'Sobre o app'),
          const SizedBox(height: 12),
          Text('Dandi Bot • versão 1.0.0', style: AppTextStyles.subtitle),
          const SizedBox(height: 8),
          Text(
            'App educativo de análise e simulação de ativos financeiros para B3, EUA e criptomoedas. Não realiza ordens, não conecta corretoras e não promete lucro.',
            style: AppTextStyles.body,
          ),
          const SizedBox(height: 12),
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'Conteúdo educativo e simulado. Não é recomendação de investimento.',
                style: AppTextStyles.body.copyWith(color: AppColors.gold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProvidersCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DandiCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(title: 'Provedores de IA'),
          const SizedBox(height: 12),
          Text(
            'MVP em modo ${AiProvider.mock.label}. O gateway já tem mapeamento para provedores futuros via backend.',
            style: AppTextStyles.body,
          ),
          const SizedBox(height: 12),
          for (final role in AgentRole.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(child: Text(role.label, style: AppTextStyles.muted)),
                  Text(
                    MockAiGatewayService.plannedProviderFor(role).label,
                    style: AppTextStyles.mono.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
          const Divider(),
          Text(
            'Fallback: ${kProviderFallbackChain.map((item) => item.label).join(' → ')}',
            style: AppTextStyles.muted,
          ),
        ],
      ),
    );
  }
}

class _ApiKeyInput extends StatefulWidget {
  const _ApiKeyInput({required this.initialValue, required this.onChanged});

  final String? initialValue;
  final ValueChanged<String?> onChanged;

  @override
  State<_ApiKeyInput> createState() => _ApiKeyInputState();
}

class _ApiKeyInputState extends State<_ApiKeyInput> {
  late final TextEditingController _controller;
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          obscureText: _obscureText,
          style: AppTextStyles.body,
          decoration: InputDecoration(
            labelText: 'Chave de API do Gemini',
            hintText: 'Digite sua chave do Google AI Studio...',
            labelStyle: AppTextStyles.subtitle,
            hintStyle: AppTextStyles.muted,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureText ? Icons.visibility_off : Icons.visibility,
                color: AppColors.muted,
              ),
              onPressed: () {
                setState(() {
                  _obscureText = !_obscureText;
                });
              },
            ),
          ),
          onChanged: (value) {
            final trimmed = value.trim();
            widget.onChanged(trimmed.isEmpty ? null : trimmed);
          },
        ),
        const SizedBox(height: 6),
        Text(
          'Insira sua chave para ativar análises e chat em tempo real com agentes inteligentes.',
          style: AppTextStyles.muted.copyWith(fontSize: 12),
        ),
      ],
    );
  }
}

class _BackendUrlInput extends StatefulWidget {
  const _BackendUrlInput({
    required this.initialValue,
    required this.isOnline,
    required this.onChanged,
    required this.onTest,
  });

  final String initialValue;
  final bool isOnline;
  final ValueChanged<String> onChanged;
  final Future<bool> Function() onTest;

  @override
  State<_BackendUrlInput> createState() => _BackendUrlInputState();
}

class _BackendUrlInputState extends State<_BackendUrlInput> {
  late final TextEditingController _controller;
  bool _testing = false;
  bool? _testResult;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _testResult = widget.isOnline ? true : null;
  }

  @override
  void didUpdateWidget(covariant _BackendUrlInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isOnline != widget.isOnline) {
      setState(() {
        _testResult = widget.isOnline;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleTest() async {
    setState(() {
      _testing = true;
      _testResult = null;
    });

    // Apply current URL before testing
    final trimmed = _controller.text.trim();
    if (trimmed.isNotEmpty) {
      widget.onChanged(trimmed);
    }

    // Small delay for settings to propagate
    await Future<void>.delayed(const Duration(milliseconds: 200));

    final result = await widget.onTest();
    if (mounted) {
      setState(() {
        _testing = false;
        _testResult = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                style: AppTextStyles.body,
                decoration: InputDecoration(
                  labelText: 'URL do Backend',
                  hintText: 'http://127.0.0.1:8000',
                  labelStyle: AppTextStyles.subtitle,
                  hintStyle: AppTextStyles.muted,
                  prefixIcon: Icon(
                    Icons.dns_rounded,
                    color: _testResult == true
                        ? Colors.green
                        : _testResult == false
                            ? Colors.red
                            : AppColors.muted,
                  ),
                ),
                onChanged: (value) {
                  final trimmed = value.trim();
                  if (trimmed.isNotEmpty) {
                    widget.onChanged(trimmed);
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _testing ? null : _handleTest,
                icon: _testing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        _testResult == true
                            ? Icons.check_circle
                            : _testResult == false
                                ? Icons.error
                                : Icons.play_arrow_rounded,
                        size: 20,
                      ),
                label: Text(
                  _testing
                      ? 'Testando…'
                      : _testResult == true
                          ? 'Conectado'
                          : _testResult == false
                              ? 'Offline'
                              : 'Testar',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _testResult == true
                      ? Colors.green.withValues(alpha: 0.15)
                      : _testResult == false
                          ? Colors.red.withValues(alpha: 0.15)
                          : null,
                  foregroundColor: _testResult == true
                      ? Colors.green
                      : _testResult == false
                          ? Colors.red
                          : null,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Endereço do api_server.py (FastAPI). Inicie com: uvicorn api_server:app --port 8000',
          style: AppTextStyles.muted.copyWith(fontSize: 12),
        ),
        if (_testResult == true) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Backend TradingAgents conectado — chat usará agentes reais',
                style: AppTextStyles.muted.copyWith(
                  fontSize: 12,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ],
        if (_testResult == false) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Backend offline — chat usará Gemini direto ou modo simulado',
                  style: AppTextStyles.muted.copyWith(
                    fontSize: 12,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

