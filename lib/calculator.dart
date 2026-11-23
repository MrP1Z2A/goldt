/// Position-size maths for XAUUSD (gold).
///
/// On most brokers 1 standard lot of XAUUSD = 100 troy ounces, so a $1.00
/// move in price is worth $100 per lot. The contract size is configurable
/// because some brokers use different sizes.
library;

import 'dart:math' as math;

enum SizingMode { riskAmount, riskPercent, targetProfit }

class LotResult {
  final bool isBuy;
  final double rawLots;
  final double lots; // rounded down to the lot step
  final double slDistance; // price distance entry -> SL
  final double? tpDistance; // price distance entry -> TP
  final double lossAtLots; // $ lost if SL is hit, using rounded lots
  final double? profitAtLots; // $ made if TP is hit, using rounded lots
  final double? riskReward; // reward / risk

  const LotResult({
    required this.isBuy,
    required this.rawLots,
    required this.lots,
    required this.slDistance,
    required this.tpDistance,
    required this.lossAtLots,
    required this.profitAtLots,
    required this.riskReward,
  });
}

class CalcError implements Exception {
  final String message;
  const CalcError(this.message);
  @override
  String toString() => message;
}

/// Rounds [value] down to a multiple of [step] (avoids floating point drift).
double floorToStep(double value, double step) {
  final n = (value / step + 1e-9).floorToDouble();
  final decimals = math.max(0, -(math.log(step) / math.ln10).floor());
  return double.parse((n * step).toStringAsFixed(decimals));
}

LotResult calculateLots({
  required double entry,
  required double stopLoss,
  double? takeProfit,
  required SizingMode mode,
  required double amount, // $ risk, % risk, or $ target profit
  double balance = 0,
  double contractSize = 100,
  double lotStep = 0.01,
}) {
  if (entry <= 0) throw const CalcError('Enter a valid entry price.');
  if (stopLoss <= 0) throw const CalcError('Enter a valid stop loss.');
  if (stopLoss == entry) {
    throw const CalcError('Stop loss cannot equal the entry price.');
  }
  if (contractSize <= 0) throw const CalcError('Contract size must be > 0.');
  if (amount <= 0) throw const CalcError('Enter an amount greater than 0.');

  final isBuy = stopLoss < entry;
  final slDistance = (entry - stopLoss).abs();

  double? tpDistance;
  if (takeProfit != null && takeProfit > 0) {
    final tpOnRightSide = isBuy ? takeProfit > entry : takeProfit < entry;
    if (!tpOnRightSide) {
      throw CalcError(isBuy
          ? 'For a BUY (SL below entry) take profit must be above entry.'
          : 'For a SELL (SL above entry) take profit must be below entry.');
    }
    tpDistance = (takeProfit - entry).abs();
  }

  double rawLots;
  switch (mode) {
    case SizingMode.riskAmount:
      rawLots = amount / (slDistance * contractSize);
    case SizingMode.riskPercent:
      if (balance <= 0) throw const CalcError('Enter your account balance.');
      rawLots = (balance * amount / 100) / (slDistance * contractSize);
    case SizingMode.targetProfit:
      if (tpDistance == null) {
        throw const CalcError('Target profit mode needs a take profit price.');
      }
      rawLots = amount / (tpDistance * contractSize);
  }

  final lots = floorToStep(rawLots, lotStep);
  return LotResult(
    isBuy: isBuy,
    rawLots: rawLots,
    lots: lots,
    slDistance: slDistance,
    tpDistance: tpDistance,
    lossAtLots: lots * slDistance * contractSize,
    profitAtLots: tpDistance == null ? null : lots * tpDistance * contractSize,
    riskReward: tpDistance == null ? null : tpDistance / slDistance,
  );
}
