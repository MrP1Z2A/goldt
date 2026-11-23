import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'calculator.dart';

void main() => runApp(const GoldtApp());

const gold = Color(0xFFD4AF37);

class GoldtApp extends StatelessWidget {
  const GoldtApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'XAUUSD Lot Calculator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: gold,
          brightness: Brightness.dark,
          primary: gold,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          isDense: true,
        ),
      ),
      home: const CalculatorPage(),
    );
  }
}

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key});

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  final _entry = TextEditingController();
  final _sl = TextEditingController();
  final _tp = TextEditingController();
  final _amount = TextEditingController(text: '100');
  final _balance = TextEditingController(text: '10000');
  final _contract = TextEditingController(text: '100');

  SizingMode _mode = SizingMode.riskAmount;

  List<TextEditingController> get _all =>
      [_entry, _sl, _tp, _amount, _balance, _contract];

  @override
  void initState() {
    super.initState();
    for (final c in _all) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in _all) {
      c.dispose();
    }
    super.dispose();
  }

  double? _num(TextEditingController c) =>
      double.tryParse(c.text.trim().replaceAll(',', ''));

  ({LotResult? result, String? error}) _compute() {
    final entry = _num(_entry);
    final sl = _num(_sl);
    if (entry == null || sl == null) {
      return (result: null, error: 'Enter entry price and stop loss.');
    }
    try {
      final r = calculateLots(
        entry: entry,
        stopLoss: sl,
        takeProfit: _num(_tp),
        mode: _mode,
        amount: _num(_amount) ?? 0,
        balance: _num(_balance) ?? 0,
        contractSize: _num(_contract) ?? 100,
      );
      return (result: r, error: null);
    } on CalcError catch (e) {
      return (result: null, error: e.message);
    }
  }

  void _clear() {
    _entry.clear();
    _sl.clear();
    _tp.clear();
  }

  @override
  Widget build(BuildContext context) {
    final out = _compute();
    return Scaffold(
      appBar: AppBar(
        title: const Text('XAUUSD Lot Calculator'),
        actions: [
          IconButton(
            tooltip: 'Clear prices',
            icon: const Icon(Icons.refresh),
            onPressed: _clear,
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _field(_entry, 'Entry price', hint: 'e.g. 2650.50'),
                _field(_sl, 'Stop loss', hint: 'e.g. 2645.00'),
                _field(_tp, 'Take profit (optional)', hint: 'e.g. 2665.00'),
                const SizedBox(height: 8),
                SegmentedButton<SizingMode>(
                  segments: const [
                    ButtonSegment(
                        value: SizingMode.riskAmount, label: Text('Risk \$')),
                    ButtonSegment(
                        value: SizingMode.riskPercent, label: Text('Risk %')),
                    ButtonSegment(
                        value: SizingMode.targetProfit,
                        label: Text('Profit \$')),
                  ],
                  selected: {_mode},
                  onSelectionChanged: (s) => setState(() => _mode = s.first),
                ),
                const SizedBox(height: 16),
                if (_mode == SizingMode.riskPercent)
                  _field(_balance, 'Account balance (\$)'),
                _field(
                  _amount,
                  switch (_mode) {
                    SizingMode.riskAmount => 'Max loss if SL hit (\$)',
                    SizingMode.riskPercent => 'Risk (% of balance)',
                    SizingMode.targetProfit => 'Target profit if TP hit (\$)',
                  },
                ),
                ExpansionTile(
                  title: const Text('Settings'),
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.only(top: 8),
                  children: [
                    _field(_contract, 'Contract size (oz per 1 lot)',
                        hint: 'Most brokers: 100'),
                  ],
                ),
                const SizedBox(height: 8),
                _ResultCard(result: out.result, error: out.error),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, {String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
        decoration: InputDecoration(labelText: label, hintText: hint),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final LotResult? result;
  final String? error;
  const _ResultCard({required this.result, required this.error});

  String _money(double v) => '\$${v.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final r = result;
    if (r == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(error ?? '', style: theme.textTheme.bodyLarge),
        ),
      );
    }
    final dirColor = r.isBuy ? Colors.greenAccent : Colors.redAccent;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Chip(
                  label: Text(r.isBuy ? 'BUY' : 'SELL',
                      style: TextStyle(
                          color: dirColor, fontWeight: FontWeight.bold)),
                ),
                const Spacer(),
                Text('Lot size', style: theme.textTheme.titleMedium),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: SelectableText(
                r.lots.toStringAsFixed(2),
                style: theme.textTheme.displayMedium
                    ?.copyWith(color: gold, fontWeight: FontWeight.bold),
              ),
            ),
            if (r.lots == 0)
              Text('Amount too small for the minimum 0.01 lot.',
                  style: TextStyle(color: theme.colorScheme.error)),
            const Divider(height: 24),
            _row('Exact lots', r.rawLots.toStringAsFixed(4)),
            _row('SL distance', r.slDistance.toStringAsFixed(2)),
            if (r.tpDistance != null)
              _row('TP distance', r.tpDistance!.toStringAsFixed(2)),
            _row('Loss if SL hit', _money(r.lossAtLots),
                color: Colors.redAccent),
            if (r.profitAtLots != null)
              _row('Profit if TP hit', _money(r.profitAtLots!),
                  color: Colors.greenAccent),
            if (r.riskReward != null)
              _row('Risk : Reward', '1 : ${r.riskReward!.toStringAsFixed(2)}'),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {Color? color}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Text(label),
            const Spacer(),
            Text(value,
                style: TextStyle(fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      );
}
