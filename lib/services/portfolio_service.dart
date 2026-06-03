import '../enums/market_type.dart';
import '../models/portfolio_item.dart';
import 'local_storage_service.dart';

class PortfolioService {
  PortfolioService(this._storage);

  final LocalStorageService _storage;

  Future<void> addItem(PortfolioItem item) async {
    final items = await getAll();
    await _storage.savePortfolio([...items, item]);
  }

  Future<void> removeItem(String id) async {
    final items = await getAll();
    await _storage.savePortfolio(items.where((item) => item.id != id).toList());
  }

  Future<List<PortfolioItem>> getAll() => _storage.loadPortfolio();

  double getTotalInvested(List<PortfolioItem> items) {
    return items.fold(0, (total, item) => total + item.totalInvested);
  }

  double getTotalCurrentValue(List<PortfolioItem> items) {
    return items.fold(0, (total, item) => total + item.currentValue);
  }

  double getTotalProfitLoss(List<PortfolioItem> items) {
    return items.fold(0, (total, item) => total + item.profitLoss);
  }

  Map<MarketType, double> getDistributionByMarket(List<PortfolioItem> items) {
    final totals = <MarketType, double>{
      MarketType.brazil: 0,
      MarketType.usa: 0,
      MarketType.crypto: 0,
    };

    for (final item in items) {
      totals[item.asset.marketType] =
          (totals[item.asset.marketType] ?? 0) + item.currentValue;
    }

    return totals;
  }
}
