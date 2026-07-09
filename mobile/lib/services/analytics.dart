import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Product analytics for MenuMind — posts directly to PostHog's HTTP `/capture`
/// endpoint (the same project as the web app and backend), tagging every event
/// `platform: mobile`.
///
/// We use the REST API rather than the `posthog_flutter` plugin on purpose: that
/// plugin pins an old Kotlin/compileSdk that clashes with this project's
/// toolchain. The REST call needs no native code — just dio + a persistent
/// anonymous install id, which doubles as the `X-Device-Id` sent to the backend
/// so server-side scan events attribute to the same person (scans-per-user).
///
/// Every call is fail-safe (fire-and-forget, never throws): analytics must never
/// break a scan.
class Analytics {
  // Public PostHog client key — the same one the web app ships (not a secret).
  static const _apiKey = 'phc_C5YAQsHrXYm8fDqWRdoN5NLqgGpWu8fv7pzH9ZPnrbp7';
  static const _host = 'https://eu.i.posthog.com';
  static const _idKey = 'analytics_install_id';

  static final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  static String? _distinctId;

  /// Load (or create) the persistent anonymous install id. Call once, before
  /// runApp().
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var id = prefs.getString(_idKey);
      if (id == null || id.isEmpty) {
        id = _newId();
        await prefs.setString(_idKey, id);
      }
      _distinctId = id;
    } catch (e) {
      debugPrint('[analytics] init failed: $e');
    }
  }

  /// The anonymous install id, for the backend's X-Device-Id header. Null until
  /// init() completes.
  static String? get distinctId => _distinctId;

  /// Emit an event. `platform: mobile` is added automatically. Fire-and-forget.
  static void capture(String event, [Map<String, dynamic>? properties]) {
    final id = _distinctId;
    if (id == null) return;
    _send(event, id, properties);
  }

  static Future<void> _send(
    String event,
    String id,
    Map<String, dynamic>? properties,
  ) async {
    try {
      await _dio.post(
        '$_host/capture/',
        data: {
          'api_key': _apiKey,
          'event': event,
          'distinct_id': id,
          'properties': {'platform': 'mobile', ...?properties},
        },
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
    } catch (e) {
      debugPrint('[analytics] capture "$event" failed: $e');
    }
  }

  /// A random 128-bit hex id (no external uuid dependency needed).
  static String _newId() {
    final r = Random.secure();
    return List<int>.generate(16, (_) => r.nextInt(256))
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
  }
}
