import 'dart:convert';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import '../models/asset.dart';
import '../utils/market_data_symbols.dart';

final _registeredViewTypes = <String>{};

class TradingViewChartFrame extends StatelessWidget {
  const TradingViewChartFrame({super.key, required this.asset});

  final Asset asset;

  @override
  Widget build(BuildContext context) {
    final viewType = _viewTypeFor(asset);
    _registerViewFactory(viewType, asset);

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: HtmlElementView(viewType: viewType),
    );
  }
}

String _viewTypeFor(Asset asset) {
  final safeTicker = asset.ticker.replaceAll(RegExp(r'[^A-Za-z0-9]'), '-');
  return 'tradingview-chart-$safeTicker';
}

void _registerViewFactory(String viewType, Asset asset) {
  if (!_registeredViewTypes.add(viewType)) return;

  ui_web.platformViewRegistry.registerViewFactory(
    viewType,
    (viewId) => _buildTradingViewElement(asset),
  );
}

web.HTMLElement _buildTradingViewElement(Asset asset) {
  final container = web.document.createElement('div') as web.HTMLDivElement;
  container.style.width = '100%';
  container.style.height = '100%';
  container.style.overflow = 'hidden';
  container.style.backgroundColor = '#05070d';

  final widget = web.document.createElement('div') as web.HTMLDivElement;
  widget.className = 'tradingview-widget-container';
  widget.style.width = '100%';
  widget.style.height = '100%';

  final chart = web.document.createElement('div') as web.HTMLDivElement;
  chart.className = 'tradingview-widget-container__widget';
  chart.style.width = '100%';
  chart.style.height = 'calc(100% - 28px)';

  final copyright = web.document.createElement('div') as web.HTMLDivElement;
  copyright.className = 'tradingview-widget-copyright';
  copyright.style.height = '28px';
  copyright.style.display = 'flex';
  copyright.style.alignItems = 'center';
  copyright.style.justifyContent = 'center';
  copyright.style.font = '12px Inter, Arial, sans-serif';
  copyright.style.backgroundColor = '#05070d';

  final link = web.document.createElement('a') as web.HTMLAnchorElement;
  link.href = MarketDataSymbols.tradingViewUrl(asset).toString();
  link.target = '_blank';
  link.rel = 'noopener nofollow';
  link.textContent = '${asset.ticker} por TradingView';
  link.style.color = '#38bdf8';
  link.style.textDecoration = 'none';

  copyright.appendChild(link);

  final script = web.document.createElement('script') as web.HTMLScriptElement;
  script.type = 'text/javascript';
  script.src =
      'https://s3.tradingview.com/external-embedding/embed-widget-advanced-chart.js';
  script.async = true;
  script.text = jsonEncode({
    'allow_symbol_change': true,
    'calendar': false,
    'details': true,
    'hide_side_toolbar': false,
    'hide_top_toolbar': false,
    'hide_legend': false,
    'hide_volume': false,
    'hotlist': false,
    'interval': 'D',
    'locale': 'br',
    'save_image': true,
    'style': '1',
    'symbol': MarketDataSymbols.tradingViewPrimarySymbol(asset),
    'theme': 'dark',
    'timezone': 'America/Sao_Paulo',
    'backgroundColor': '#05070d',
    'gridColor': 'rgba(56, 189, 248, 0.10)',
    'withdateranges': true,
    'compareSymbols': [],
    'studies': [],
    'autosize': true,
  });

  widget.appendChild(chart);
  widget.appendChild(copyright);
  widget.appendChild(script);
  container.appendChild(widget);

  return container;
}
