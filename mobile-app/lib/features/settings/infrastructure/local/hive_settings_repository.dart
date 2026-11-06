import 'dart:async';

import 'package:hive_ce/hive.dart';
import 'package:leafcheck/features/settings/domain/settings.dart';
import 'package:uuid/uuid.dart';

/// Preferences in Hive. The device id is a UUID made once on first launch.
class HiveSettingsRepository implements SettingsRepository {
  HiveSettingsRepository(
    this._box, {
    required this.serverUrl,
    required this.hasAccessKey,
  }) {
    if (_box.get('device_id') == null) {
      unawaited(_box.put('device_id', const Uuid().v4()));
    }
  }

  final Box<dynamic> _box;
  final String serverUrl;
  final bool hasAccessKey;

  @override
  AppSettings load() => AppSettings(
    serverUrl: serverUrl,
    deviceId: _box.get('device_id') as String,
    theme: ThemePreference.values.byName(
      _box.get('theme', defaultValue: ThemePreference.light.name) as String,
    ),
    reduceMotion: _box.get('reduce_motion', defaultValue: false) as bool,
    hasAccessKey: hasAccessKey,
    onboarded: _box.get('onboarded', defaultValue: false) as bool,
  );

  @override
  Future<void> save(AppSettings s) async {
    await _box.put('theme', s.theme.name);
    await _box.put('reduce_motion', s.reduceMotion);
    await _box.put('onboarded', s.onboarded);
  }
}
