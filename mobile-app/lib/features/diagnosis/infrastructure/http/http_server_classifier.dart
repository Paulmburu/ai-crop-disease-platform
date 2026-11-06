import 'package:dio/dio.dart';
import 'package:leafcheck/core/result/result.dart';
import 'package:leafcheck/features/diagnosis/domain/entities/prediction.dart';
import 'package:leafcheck/features/diagnosis/domain/enums/diagnosis_enums.dart';
import 'package:leafcheck/features/diagnosis/domain/repositories/ports.dart';
import 'package:leafcheck/features/diagnosis/infrastructure/litert/litert_classifier.dart';
import 'package:leafcheck/shared/http/api_client.dart';

/// Second opinion: uploads the photo to `POST /api/v1/predictions`
/// (go-backend → python-ml-service). Only when the user asks.
class HttpServerClassifier implements Classifier {
  HttpServerClassifier(this.api);
  final ApiClient api;

  @override
  Future<Result<Prediction>> classify(String imagePath) async {
    final r = await api.guard(() async {
      final bytes = await LiteRtClassifier.readPhoto(imagePath);
      final name = imagePath.split('/').last;
      return api.dio.post<Map<String, dynamic>>(
        '/api/v1/predictions',
        queryParameters: {'top_k': 3},
        data: FormData.fromMap({
          'file': MultipartFile.fromBytes(
            bytes,
            filename: name,
            contentType: DioMediaType(
              'image',
              name.toLowerCase().endsWith('.png') ? 'png' : 'jpeg',
            ),
          ),
        }),
      );
    });
    return switch (r) {
      Err(:final failure) => Err(failure),
      Ok(:final value) => Ok(_parse(value.data!)),
    };
  }

  static Prediction _parse(Map<String, dynamic> j) => Prediction(
    scores: [
      for (final s in (j['top_k'] as List).cast<Map<String, dynamic>>())
        (
          condition: DiagnosisCondition.fromLabel(s['class_name'] as String),
          probability: (s['confidence'] as num).toDouble(),
        ),
    ],
    threshold: (j['confidence_threshold'] as num).toDouble(),
    modelVersion: j['model_version'] as String,
    latencyMs: (j['inference_ms'] as num).toDouble(),
    source: PredictionSource.server,
  );
}
