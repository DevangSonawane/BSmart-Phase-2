import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/ad_config.dart';

class AdMobService {
  AdMobService._();

  static final AdMobService instance = AdMobService._();
  static const String _successfulPostCountKeyPrefix =
      'admob_successful_post_count_v1';

  bool _initialized = false;
  bool _loadingInterstitial = false;
  InterstitialAd? _interstitialAd;
  final Map<String, int> _successfulPostCountCache = <String, int>{};

  bool get isAndroidSupported =>
      defaultTargetPlatform == TargetPlatform.android;

  String _successfulPostCountKey(String userId) =>
      '$_successfulPostCountKeyPrefix:${userId.trim()}';

  Future<int> _readSuccessfulPostCount(String userId) async {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) return 0;
    final cached = _successfulPostCountCache[normalizedUserId];
    if (cached != null) return cached;
    try {
      final prefs = await SharedPreferences.getInstance();
      final count =
          prefs.getInt(_successfulPostCountKey(normalizedUserId)) ?? 0;
      _successfulPostCountCache[normalizedUserId] = count;
      return count;
    } catch (e, st) {
      debugPrint('Failed to read ad counter: $e');
      debugPrint(st.toString());
      return 0;
    }
  }

  Future<int> _incrementSuccessfulPostCount(String userId) async {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) return 0;
    final next = (await _readSuccessfulPostCount(normalizedUserId)) + 1;
    _successfulPostCountCache[normalizedUserId] = next;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_successfulPostCountKey(normalizedUserId), next);
    } catch (e, st) {
      debugPrint('Failed to persist ad counter: $e');
      debugPrint(st.toString());
    }
    return next;
  }

  Future<void> initialize() async {
    if (!isAndroidSupported || _initialized) return;
    _initialized = true;
    try {
      await MobileAds.instance.initialize();
    } catch (e, st) {
      debugPrint('AdMob initialization failed: $e');
      debugPrint(st.toString());
      return;
    }
    preloadInterstitial();
  }

  void preloadInterstitial() {
    if (!isAndroidSupported ||
        _loadingInterstitial ||
        _interstitialAd != null) {
      return;
    }
    _loadingInterstitial = true;
    InterstitialAd.load(
      adUnitId: AdConfig.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _loadingInterstitial = false;
          _interstitialAd = ad;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (ad) {
              debugPrint('Interstitial ad showed.');
            },
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              if (_interstitialAd == ad) {
                _interstitialAd = null;
              }
              preloadInterstitial();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('Interstitial failed to show: $error');
              ad.dispose();
              if (_interstitialAd == ad) {
                _interstitialAd = null;
              }
              preloadInterstitial();
            },
          );
        },
        onAdFailedToLoad: (error) {
          _loadingInterstitial = false;
          debugPrint('Interstitial failed to load: $error');
          _interstitialAd = null;
        },
      ),
    );
  }

  Future<void> showInterstitialAfterPostPublish() async {
    if (!isAndroidSupported) return;
    final ad = _interstitialAd;
    if (ad == null) {
      preloadInterstitial();
      return;
    }
    _interstitialAd = null;
    try {
      ad.show();
    } catch (e, st) {
      debugPrint('Interstitial show threw: $e');
      debugPrint(st.toString());
      ad.dispose();
      preloadInterstitial();
    }
  }

  Future<bool> recordSuccessfulPostAndMaybeShowInterstitial({
    required String userId,
  }) async {
    if (!isAndroidSupported) return false;
    final count = await _incrementSuccessfulPostCount(userId);
    if (count <= 0 || count % 5 != 0) return false;
    await showInterstitialAfterPostPublish();
    return true;
  }
}
