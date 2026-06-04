import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app.dart';

class BottomNav extends StatelessWidget {
  const BottomNav({super.key, required this.currentPath});

  final String currentPath;

  @override
  Widget build(BuildContext context) {
    final destinations = [
      _Destination(routeHome, Icons.home_rounded, 'Home'),
      _Destination(routeMarkets, Icons.query_stats_rounded, 'Mercados'),
      _Destination(
        routePortfolio,
        Icons.account_balance_wallet_rounded,
        'Carteira',
      ),
      _Destination(routeChat, Icons.chat_bubble_outline_rounded, 'Chat'),
      _Destination(routeNews, Icons.newspaper_rounded, 'Noticias'),
      _Destination(routeSettings, Icons.person_outline_rounded, 'Perfil'),
    ];
    final index = destinations.indexWhere((item) => item.path == currentPath);

    return NavigationBar(
      selectedIndex: index < 0 ? 0 : index,
      onDestinationSelected: (next) => context.go(destinations[next].path),
      destinations: [
        for (final item in destinations)
          NavigationDestination(icon: Icon(item.icon), label: item.label),
      ],
    );
  }
}

class _Destination {
  const _Destination(this.path, this.icon, this.label);
  final String path;
  final IconData icon;
  final String label;
}
