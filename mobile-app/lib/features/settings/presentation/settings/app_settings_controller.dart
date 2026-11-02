import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:leafcheck/app/di/providers.dart';
import 'package:leafcheck/features/settings/domain/settings.dart';

/// App-wide settings (theme, reduce motion). Read by `App` and Settings.
class AppSettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() => ref.watch(settingsRepositoryProvider).load();

  Future<void> setTheme(ThemePreference theme) =>
      _save(state.copyWith(theme: theme));

  Future<void> completeOnboarding() => _save(state.copyWith(onboarded: true));

  Future<void> setReduceMotion({required bool value}) =>
      _save(state.copyWith(reduceMotion: value));

  Future<void> _save(AppSettings s) async {
    state = s;
    await ref.read(updateSettingsProvider)(s);
  }
}

final appSettingsProvider =
    NotifierProvider<AppSettingsController, AppSettings>(
      AppSettingsController.new,
    );
