import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:leafcheck/app/di/providers.dart';
import 'package:leafcheck/features/diagnosis/domain/entities/diagnosis.dart';

/// All local diagnoses, newest first (Scan recent list, History).
final historyProvider = StreamProvider<List<Diagnosis>>(
  (ref) => ref.watch(watchHistoryProvider)(),
);
