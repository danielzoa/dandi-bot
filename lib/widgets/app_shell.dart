import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../app.dart';
import '../services/app_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/responsive_layout.dart';
import 'bottom_nav.dart';
import 'side_nav.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final _scrollController = ScrollController();
  Timer? _newsTimer;
  bool _newsRefreshStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_newsRefreshStarted) return;
    _newsRefreshStarted = true;
    final controller = DandiScope.of(context);
    unawaited(controller.refreshNews());
    _newsTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => unawaited(controller.refreshNews()),
    );
  }

  @override
  void dispose() {
    _newsTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    final mobile = ResponsiveLayout.isMobile(context);

    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.digit1, control: true):
            _NavigateIntent(routeHome),
        SingleActivator(LogicalKeyboardKey.digit2, control: true):
            _NavigateIntent(routeMarkets),
        SingleActivator(LogicalKeyboardKey.digit3, control: true):
            _NavigateIntent(routePortfolio),
        SingleActivator(LogicalKeyboardKey.digit4, control: true):
            _NavigateIntent(routeHistory),
        SingleActivator(LogicalKeyboardKey.digit5, control: true):
            _NavigateIntent(routeChat),
        SingleActivator(LogicalKeyboardKey.digit6, control: true):
            _NavigateIntent(routeSettings),
        SingleActivator(LogicalKeyboardKey.f1): _ShowShortcutHelpIntent(),
      },
      child: Actions(
        actions: {
          _NavigateIntent: CallbackAction<_NavigateIntent>(
            onInvoke: (intent) {
              context.go(intent.route);
              return null;
            },
          ),
          _ShowShortcutHelpIntent: CallbackAction<_ShowShortcutHelpIntent>(
            onInvoke: (intent) {
              _showShortcutHelp(context);
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            bottomNavigationBar: mobile ? BottomNav(currentPath: path) : null,
            body: Stack(
              children: [
                const _TerminalBackground(),
                Row(
                  children: [
                    if (!mobile) SideNav(currentPath: path),
                    Expanded(
                      child: SafeArea(
                        child: Column(
                          children: [
                            _TopHeader(mobile: mobile),
                            Expanded(
                              child: Scrollbar(
                                controller: _scrollController,
                                thumbVisibility: !mobile,
                                child: SingleChildScrollView(
                                  controller: _scrollController,
                                  padding: EdgeInsets.all(mobile ? 14 : 20),
                                  child: Align(
                                    alignment: Alignment.topCenter,
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxWidth: 1480,
                                      ),
                                      child: widget.child,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            _EducationalFooter(
                              onHelp: () => _showShortcutHelp(context),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TerminalBackground extends StatelessWidget {
  const _TerminalBackground();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.92, -1),
            radius: 1.25,
            colors: [Color(0x291D4ED8), AppColors.background],
            stops: [0, 0.58],
          ),
        ),
        child: CustomPaint(painter: _GridPainter()),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.blueBright.withValues(alpha: 0.035)
      ..strokeWidth = 1;
    const step = 32.0;

    for (var x = 0.0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TopHeader extends StatelessWidget {
  const _TopHeader({required this.mobile});

  final bool mobile;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.backgroundDeep.withValues(alpha: 0.84),
        border: const Border(bottom: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: AppColors.blueBright.withValues(alpha: 0.05),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: mobile ? 12 : 20,
          vertical: mobile ? 10 : 12,
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                textInputAction: TextInputAction.search,
                onSubmitted: (value) {
                  final ticker = value.trim();
                  if (ticker.isEmpty) return;
                  context.go(
                    '$routeAnalysis?ticker=${Uri.encodeComponent(ticker)}',
                  );
                },
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search_rounded, size: 20),
                  hintText: 'Buscar ticker, ativo ou pergunta...',
                  isDense: true,
                ),
              ),
            ),
            if (!mobile) ...[const SizedBox(width: 18), const _MarketStatus()],
            const SizedBox(width: 10),
            IconButton(
              tooltip: 'Noticias',
              onPressed: () => context.go(routeNews),
              icon: const Icon(Icons.notifications_none_rounded),
            ),
            IconButton(
              tooltip: 'Configuracoes',
              onPressed: () => context.go(routeSettings),
              icon: const Icon(Icons.tune_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _MarketStatus extends StatelessWidget {
  const _MarketStatus();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Mercados', style: AppTextStyles.muted),
        const SizedBox(width: 10),
        const _StatusDot(),
        const SizedBox(width: 6),
        Text(
          'Aberto',
          style: AppTextStyles.muted.copyWith(color: AppColors.teal),
        ),
      ],
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.teal,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.teal.withValues(alpha: 0.35),
            blurRadius: 12,
          ),
        ],
      ),
      child: const SizedBox(width: 8, height: 8),
    );
  }
}

class _NavigateIntent extends Intent {
  const _NavigateIntent(this.route);

  final String route;
}

class _ShowShortcutHelpIntent extends Intent {
  const _ShowShortcutHelpIntent();
}

void _showShortcutHelp(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final shortcuts = [
        ('Ctrl + 1', 'Home'),
        ('Ctrl + 2', 'Mercados'),
        ('Ctrl + 3', 'Carteira'),
        ('Ctrl + 4', 'Histórico'),
        ('Ctrl + 5', 'Chat'),
        ('Ctrl + 6', 'Configurações'),
        ('Ctrl + K', 'Focar busca na Home'),
        ('Ctrl + Enter', 'Enviar mensagem no chat'),
        ('F1', 'Mostrar estes atalhos'),
      ];

      return AlertDialog(
        title: const Text('Comandos de teclado'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final shortcut in shortcuts)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          child: Text(
                            shortcut.$1,
                            style: AppTextStyles.mono.copyWith(fontSize: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(shortcut.$2, style: AppTextStyles.body),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Fechar'),
          ),
        ],
      );
    },
  );
}

class _EducationalFooter extends StatelessWidget {
  const _EducationalFooter({required this.onHelp});

  final VoidCallback onHelp;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.backgroundDeep,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.shield_outlined,
              color: AppColors.blueBright,
              size: 16,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Conteúdo educativo e simulado. Não é recomendação de investimento.',
                textAlign: TextAlign.center,
                style: AppTextStyles.muted,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Atalhos do teclado (F1)',
              visualDensity: VisualDensity.compact,
              onPressed: onHelp,
              icon: const Icon(
                Icons.keyboard_outlined,
                color: AppColors.muted,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
