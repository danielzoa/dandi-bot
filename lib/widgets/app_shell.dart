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
            body: Row(
              children: [
                if (!mobile) SideNav(currentPath: path),
                Expanded(
                  child: SafeArea(
                    child: Column(
                      children: [
                        Expanded(
                          child: Scrollbar(
                            controller: _scrollController,
                            thumbVisibility: !mobile,
                            child: SingleChildScrollView(
                              controller: _scrollController,
                              padding: EdgeInsets.all(mobile ? 14 : 22),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 1280,
                                ),
                                child: widget.child,
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
          ),
        ),
      ),
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
        color: AppColors.background,
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
