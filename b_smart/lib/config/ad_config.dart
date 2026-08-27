import 'package:flutter/foundation.dart';

class AdConfig {
  static const String androidAppId = 'ca-app-pub-6848080783292385~6565575168';

  static const String _bannerTestAdUnitId =
      'ca-app-pub-3940256099942544/6300978111';
  static const String _interstitialTestAdUnitId =
      'ca-app-pub-3940256099942544/1033173712';
  static const String _nativeTestAdUnitId =
      'ca-app-pub-3940256099942544/2247696110';

  static const String _bannerProductionAdUnitId =
      'ca-app-pub-6848080783292385/7997699035';
  static const String _interstitialProductionAdUnitId =
      'ca-app-pub-6848080783292385/5739578658';
  static const String _nativeProductionAdUnitId =
      'ca-app-pub-6848080783292385/7115862201';

  static const String nativeAdFactoryId = 'bsmart_native_ad_factory';

  static bool get useProductionAds => kReleaseMode;

  static String get bannerAdUnitId =>
      useProductionAds ? _bannerProductionAdUnitId : _bannerTestAdUnitId;

  static String get interstitialAdUnitId => useProductionAds
      ? _interstitialProductionAdUnitId
      : _interstitialTestAdUnitId;

  static String get nativeAdUnitId =>
      useProductionAds ? _nativeProductionAdUnitId : _nativeTestAdUnitId;
}
