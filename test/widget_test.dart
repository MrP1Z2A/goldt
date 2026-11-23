import 'package:flutter_test/flutter_test.dart';
import 'package:goldt/calculator.dart';

void main() {
  test('buy: risk \$100 with \$5 stop = 0.20 lots', () {
    final r = calculateLots(
      entry: 2650,
      stopLoss: 2645,
      takeProfit: 2665,
      mode: SizingMode.riskAmount,
      amount: 100,
    );
    expect(r.isBuy, true);
    expect(r.lots, 0.20);
    expect(r.lossAtLots, closeTo(100, 1e-9));
    expect(r.profitAtLots, closeTo(300, 1e-9));
    expect(r.riskReward, closeTo(3, 1e-9));
  });

  test('sell: 1% of 10,000 with \$3 stop rounds down to 0.33', () {
    final r = calculateLots(
      entry: 2650,
      stopLoss: 2653,
      mode: SizingMode.riskPercent,
      amount: 1,
      balance: 10000,
    );
    expect(r.isBuy, false);
    expect(r.lots, 0.33);
  });

  test('target profit \$500 with \$10 TP = 0.50 lots', () {
    final r = calculateLots(
      entry: 2650,
      stopLoss: 2640,
      takeProfit: 2660,
      mode: SizingMode.targetProfit,
      amount: 500,
    );
    expect(r.lots, 0.50);
    expect(r.lossAtLots, closeTo(500, 1e-9));
  });

  test('TP on wrong side throws', () {
    expect(
      () => calculateLots(
        entry: 2650,
        stopLoss: 2640,
        takeProfit: 2630,
        mode: SizingMode.riskAmount,
        amount: 100,
      ),
      throwsA(isA<CalcError>()),
    );
  });
}
