import 'asset.dart';

class PortfolioItem {
  const PortfolioItem({
    required this.id,
    required this.asset,
    required this.quantity,
    required this.entryPrice,
    required this.currentSimulatedPrice,
    this.note,
    required this.createdAt,
  });

  final String id;
  final Asset asset;
  final double quantity;
  final double entryPrice;
  final double currentSimulatedPrice;
  final String? note;
  final DateTime createdAt;

  double get totalInvested => quantity * entryPrice;
  double get currentValue => quantity * currentSimulatedPrice;
  double get profitLoss => currentValue - totalInvested;
  double get profitLossPercent =>
      totalInvested == 0 ? 0 : (profitLoss / totalInvested) * 100;

  Map<String, dynamic> toJson() => {
    'id': id,
    'asset': asset.toJson(),
    'quantity': quantity,
    'entryPrice': entryPrice,
    'currentSimulatedPrice': currentSimulatedPrice,
    'note': note,
    'createdAt': createdAt.toIso8601String(),
  };

  factory PortfolioItem.fromJson(Map<String, dynamic> json) {
    return PortfolioItem(
      id: json['id'] as String,
      asset: Asset.fromJson(json['asset'] as Map<String, dynamic>),
      quantity: (json['quantity'] as num).toDouble(),
      entryPrice: (json['entryPrice'] as num).toDouble(),
      currentSimulatedPrice: (json['currentSimulatedPrice'] as num).toDouble(),
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
