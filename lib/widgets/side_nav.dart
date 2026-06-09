import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'dandi_bot_avatar.dart';

class SideNav extends StatelessWidget {
  const SideNav({super.key, required this.currentPath});

  final String currentPath;

  @override
  Widget build(BuildContext context) {
    final items = [
      _NavItem(routeHome, Icons.home_rounded, 'Dashboard', 'Visao geral'),
      _NavItem(routeMarkets, Icons.query_stats_rounded, 'Mercado'),
      _NavItem(
        routePortfolio,
        Icons.account_balance_wallet_rounded,
        'Carteira',
        'Posicoes e performance',
      ),
      _NavItem(routeAnalysis, Icons.show_chart_rounded, 'Grafico'),
      _NavItem(routeNews, Icons.newspaper_rounded, 'Noticias'),
      _NavItem(routeChat, Icons.smart_toy_outlined, 'IA'),
      _NavItem(routeMarketCatalog, Icons.filter_list_rounded, 'Screeners'),
      _NavItem(routeHistory, Icons.notifications_rounded, 'Alertas'),
      _NavItem(routeSettings, Icons.settings_rounded, 'Configuracoes'),
    ];

    return SizedBox(
      width: 240,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.backgroundDeep.withValues(alpha: 0.92),
          border: const Border(right: BorderSide(color: AppColors.border)),
          boxShadow: [
            BoxShadow(
              color: AppColors.blueBright.withValues(alpha: 0.04),
              blurRadius: 32,
              offset: const Offset(12, 0),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const DandiBotAvatar(size: 42),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'DanDiBot',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.title,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                for (final item in items)
                  _NavButton(item: item, active: _isActive(item.path)),
                const Spacer(),
                const _ConnectionStatus(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _isActive(String path) {
    if (path == routeHome) return currentPath == routeHome;
    if (path == routeMarkets) return currentPath == routeMarkets;
    return currentPath.startsWith(path);
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.item, required this.active});

  final _NavItem item;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => context.go(item.path),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: active
                ? AppColors.blueBright.withValues(alpha: 0.10)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: active ? Border.all(color: AppColors.borderActive) : null,
            boxShadow: active
                ? [
                    BoxShadow(
                      color: AppColors.blueBright.withValues(alpha: 0.08),
                      blurRadius: 18,
                    ),
                  ]
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  color: active ? AppColors.blueBright : AppColors.muted,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: active ? AppColors.white : AppColors.muted,
                          fontWeight: active
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                      if (item.subtitle != null)
                        Text(
                          item.subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.muted.copyWith(fontSize: 11),
                        ),
                    ],
                  ),
                ),
                if (active)
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.blueBright,
                    size: 18,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ConnectionStatus extends StatelessWidget {
  const _ConnectionStatus();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.teal,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.teal.withValues(alpha: 0.3),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: const SizedBox(width: 10, height: 10),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Conexao Premium',
                    style: AppTextStyles.subtitle.copyWith(fontSize: 13),
                  ),
                  Text('Baixa latencia', style: AppTextStyles.muted),
                ],
              ),
            ),
            const Icon(Icons.diamond_rounded, color: AppColors.teal, size: 16),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.path, this.icon, this.label, [this.subtitle]);

  final String path;
  final IconData icon;
  final String label;
  final String? subtitle;
}
