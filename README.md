# XAUUSD Lot Calculator (goldt)

Flutter app for Windows and Android that tells you how many lots of gold (XAUUSD) to open.

## How it works

1 standard lot of XAUUSD = 100 oz, so a $1.00 price move = $100 per lot (contract size is editable in Settings).

Enter **entry price**, **stop loss** and (optionally) **take profit**, then pick a sizing mode:

| Mode | Formula |
|------|---------|
| Risk $ | lots = max loss ÷ (\|entry − SL\| × 100) |
| Risk % | lots = (balance × % ÷ 100) ÷ (\|entry − SL\| × 100) |
| Profit $ | lots = target profit ÷ (\|TP − entry\| × 100) |

Lots are rounded **down** to 0.01. BUY/SELL is detected from which side the stop loss is on. The app also shows loss at SL, profit at TP, and risk:reward.

Example: entry 2650, SL 2645, risk $100 → 100 ÷ (5 × 100) = **0.20 lots**.

## Downloads

Every push to `main` runs GitHub Actions, which builds `goldt.apk` (Android) and `goldt-windows.zip` (Windows, unzip and run `goldt.exe`) and attaches them to a release on the [Releases page](../../releases).

## Build locally

```
flutter test
flutter build windows --release   # build/windows/x64/runner/Release/goldt.exe
flutter build apk --release       # needs the Android SDK
```
