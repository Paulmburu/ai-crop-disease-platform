import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:leafcheck/app/di/providers.dart';
import 'package:leafcheck/core/constants/app_constants.dart';
import 'package:leafcheck/core/result/result.dart';
import 'package:leafcheck/features/diagnosis/domain/entities/diagnosis.dart';

/// Runs DiagnoseLeaf for a photo, held for at least
/// [AppConstants.minAnalyzingHold] so the scan reads on stage.
final analyzeProvider = FutureProvider.autoDispose
    .family<Result<Diagnosis>, String>((ref, imagePath) async {
      final hold = Future<void>.delayed(AppConstants.minAnalyzingHold);
      final result = await ref.read(diagnoseLeafProvider)(imagePath);
      await hold;
      return result;
    });
