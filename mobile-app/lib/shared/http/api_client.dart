import 'package:dio/dio.dart';
import 'package:leafcheck/core/result/failure.dart';
import 'package:leafcheck/core/result/result.dart';
import 'package:uuid/uuid.dart';

/// Where the app finds go-backend. Override per run:
/// `flutter run --dart-define=SERVER_URL=http://192.168.1.20:8080 --dart-define=API_KEY=...`
abstract final class BackendConfig {
  /// 10.0.2.2 is the host machine as seen from the Android emulator.
  static const serverUrl = String.fromEnvironment(
    'SERVER_URL',
    defaultValue: 'http://10.0.2.2:8080',
  );

  // ponytail: key from --dart-define (local dev key by default); move to
  // flutter_secure_storage with an entry screen before any real deployment.
  static const apiKey = String.fromEnvironment(
    'API_KEY',
    defaultValue: 'dev-key',
  );
}

/// The one Dio the app uses (AGENTS.md). Adds `X-API-Key` and `X-Request-ID`
/// to every call and maps errors to [Failure]s.
class ApiClient {
  ApiClient({required String baseUrl, required String apiKey, Dio? dio})
    : dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: baseUrl,
              connectTimeout: const Duration(seconds: 5),
              receiveTimeout: const Duration(seconds: 30),
              headers: {'X-API-Key': apiKey},
            ),
          ) {
    this.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (o, h) {
          o.headers['X-Request-ID'] = const Uuid().v4();
          h.next(o);
        },
      ),
    );
  }

  final Dio dio;

  /// Runs [call] and turns any thrown error into an `Err`.
  Future<Result<T>> guard<T>(Future<T> Function() call) async {
    try {
      return Ok(await call());
    } on Object catch (e) {
      return Err(failureOf(e));
    }
  }

  /// Error body shape shared by every service:
  /// `{"error": "...", "detail": "...", "request_id": "..."}`.
  static Failure failureOf(Object e) {
    if (e is! DioException) return Unexpected(e);
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
      case DioExceptionType.connectionError:
        return const Offline();
      case DioExceptionType.badResponse:
      case DioExceptionType.badCertificate:
      case DioExceptionType.cancel:
      case DioExceptionType.unknown:
        break;
    }
    final status = e.response?.statusCode;
    final body = e.response?.data;
    final map = body is Map ? body : const <String, Object?>{};
    final code = map['error'] is String ? map['error'] as String : 'error';
    final requestId = map['request_id'] as String?;
    final detail = map['detail'];
    if (status == 401) return const Unauthorized();
    if (status == 503 || status == 502 || status == 504) {
      return ServerUnavailable(code: code, requestId: requestId);
    }
    if (status != null && status >= 400 && status < 500) {
      return Invalid(code: code, detail: detail is String ? detail : '$detail');
    }
    return Unexpected(e, requestId: requestId);
  }
}
