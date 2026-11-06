import 'package:flutter/material.dart';

/// The one icon set used across the app (Material outlined, matching the
/// designs). Screens never pick icons ad hoc, so they stay consistent.
abstract final class AppIcons {
  // Navigation
  static const IconData scan = Icons.photo_camera_outlined;
  static const IconData scanActive = Icons.photo_camera;
  static const IconData history = Icons.history;
  static const IconData settings = Icons.settings_outlined;
  static const IconData settingsActive = Icons.settings;
  static const IconData back = Icons.arrow_back;
  static const IconData close = Icons.close;
  static const IconData help = Icons.help_outline;
  static const IconData chevron = Icons.chevron_right;

  // Status
  static const IconData model = Icons.memory;
  static const IconData online = Icons.cloud_done_outlined;
  static const IconData offline = Icons.cloud_off_outlined;
  static const IconData pending = Icons.schedule;
  static const IconData error = Icons.error_outline;
  static const IconData check = Icons.check_circle_outline;
  static const IconData sync = Icons.sync;
  static const IconData upload = Icons.cloud_upload_outlined;
  static const IconData download = Icons.download;
  static const IconData refresh = Icons.refresh;

  // Diagnosis
  static const IconData healthy = Icons.check_circle_outline;
  static const IconData earlyBlight = Icons.warning_amber_rounded;
  static const IconData lateBlight = Icons.coronavirus_outlined;
  static const IconData uncertain = Icons.help_outline;

  // Content
  static const IconData camera = Icons.photo_camera_outlined;
  static const IconData gallery = Icons.photo_library_outlined;
  static const IconData sample = Icons.eco_outlined;
  static const IconData advice = Icons.chat_outlined;
  static const IconData send = Icons.send;
  static const IconData delete = Icons.delete_outline;
  static const IconData sun = Icons.wb_sunny_outlined;
  static const IconData leaf = Icons.eco_outlined;
  static const IconData focus = Icons.center_focus_strong_outlined;
  static const IconData source = Icons.description_outlined;
  static const IconData openExternal = Icons.open_in_new;
  static const IconData info = Icons.info_outline;
  static const IconData shieldFail = Icons.gpp_bad_outlined;
  static const IconData build = Icons.build_outlined;
  static const IconData speed = Icons.speed;
  static const IconData replay = Icons.replay;
  static const IconData server = Icons.dns_outlined;
  static const IconData key = Icons.key_outlined;
  static const IconData health = Icons.monitor_heart_outlined;
  static const IconData darkMode = Icons.dark_mode_outlined;
  static const IconData motionOff = Icons.motion_photos_off_outlined;
  static const IconData phone = Icons.smartphone;
  static const IconData arrowForward = Icons.arrow_forward;
}
