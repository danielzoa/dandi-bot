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
      _NavItem(routeHome, Icons.home_rounded, 'Home'),
      _NavItem(routeMarkets, Icons.query_stats_rounded, 'Mercados'),
      _NavItem(
        routePortfolio,
        Icons.account_balance_wallet_rounded,
        'Carteira Simulada',
      ),
      _NavItem(routeHistory, Icons.history_rounded, 'Histórico'),
      _NavItem(routeChat, Icons.chat_bubble_outline_rounded, 'Chat com IA'),
      _NavItem(routeNews, Icons.newspaper_rounded, 'Noticias'),
      _NavItem(routeSettings, Icons.settings_rounded, 'Configurações'),
    ];

    return SizedBox(
      width: 240,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(right: BorderSide(color: AppColors.border)),
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
                    Text('Dandi Bot', style: AppTextStyles.subtitle),
                  ],
                ),
                const SizedBox(height: 24),
                for (final item in items)
                  _NavButton(item: item, active: currentPath == item.path),
                const Spacer(),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.blue,
                          child: Icon(Icons.person, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Investidor',
                                style: AppTextStyles.subtitle.copyWith(
                                  fontSize: 13,
                                ),
                              ),
                              Text('Moderado', style: AppTextStyles.muted),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.expand_more,
                          size: 18,
                          color: AppColors.muted,
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

class _NavButton extends StatelessWidget {
  const _NavButton({required this.item, required this.active});

  final _NavItem item;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.go(item.path),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: active
                ? AppColors.blue.withValues(alpha: 0.34)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: active
                ? Border.all(color: AppColors.blue.withValues(alpha: 0.42))
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  color: active ? AppColors.blueBright : AppColors.muted,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      color: active ? AppColors.white : AppColors.muted,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
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

class _NavItem {
  const _NavItem(this.path, this.icon, this.label);
  final String path;
  final IconData icon;
  final String label;
}
