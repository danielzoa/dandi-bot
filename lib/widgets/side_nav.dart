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
      _NavItem.custom(routeMarketCatalog, 'screeners', 'Screeners'),
      _NavItem.custom(routeHistory, 'alerts', 'Alertas'),
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
                _NavIcon(item: item, active: active),
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

class _NavIcon extends StatelessWidget {
  const _NavIcon({required this.item, required this.active});

  final _NavItem item;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.blueBright : AppColors.muted;
    final customIcon = item.customIcon;

    if (customIcon == 'screeners') {
      return CustomPaint(
        size: const Size.square(20),
        painter: _ScreenersIconPainter(color),
      );
    }

    if (customIcon == 'alerts') {
      return CustomPaint(
        size: const Size.square(20),
        painter: _AlertsIconPainter(color),
      );
    }

    return Icon(item.icon, color: color, size: 20);
  }
}

class _ScreenersIconPainter extends CustomPainter {
  const _ScreenersIconPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;
    final knobPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final lines = [(0.22, 0.32, 0.70), (0.50, 0.48, 0.30), (0.78, 0.66, 0.56)];

    for (final line in lines) {
      final y = size.height * line.$1;
      canvas.drawLine(
        Offset(size.width * 0.12, y),
        Offset(size.width * 0.88, y),
        paint,
      );
      canvas.drawCircle(
        Offset(size.width * line.$2, y),
        size.width * 0.075,
        knobPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ScreenersIconPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _AlertsIconPainter extends CustomPainter {
  const _AlertsIconPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    final centerX = size.width * 0.5;
    final top = size.height * 0.22;
    final bottom = size.height * 0.72;
    final path = Path()
      ..moveTo(centerX, top)
      ..cubicTo(
        size.width * 0.28,
        top,
        size.width * 0.22,
        size.height * 0.42,
        size.width * 0.22,
        bottom,
      )
      ..lineTo(size.width * 0.78, bottom)
      ..cubicTo(
        size.width * 0.78,
        size.height * 0.42,
        size.width * 0.72,
        top,
        centerX,
        top,
      );
    canvas.drawPath(path, paint);
    canvas.drawLine(
      Offset(size.width * 0.18, bottom),
      Offset(size.width * 0.82, bottom),
      paint,
    );
    canvas.drawCircle(
      Offset(centerX, size.height * 0.84),
      size.width * 0.06,
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _AlertsIconPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _NavItem {
  const _NavItem(this.path, this.icon, this.label, [this.subtitle])
    : customIcon = null;

  const _NavItem.custom(this.path, this.customIcon, this.label)
    : icon = null,
      subtitle = null;

  final String path;
  final IconData? icon;
  final String? customIcon;
  final String label;
  final String? subtitle;
}
