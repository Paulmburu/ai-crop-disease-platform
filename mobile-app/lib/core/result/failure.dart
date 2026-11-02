/// Every way a use case can fail (PRD §5). The UI maps each one to a single
/// message and action with an exhaustive `switch`.
sealed class Failure {
  const Failure();
}

/// No network, or `GET /ready` did not answer within 2 s.
final class Offline extends Failure {
  const Offline();
}

/// The server answered 401: the access key is wrong or missing.
final class Unauthorized extends Failure {
  const Unauthorized();
}

/// 503 `*_unavailable`: an upstream service (advice, prediction) is down.
final class ServerUnavailable extends Failure {
  const ServerUnavailable({required this.code, this.requestId});
  final String code;
  final String? requestId;
}

/// 4xx with a reason the user can act on (e.g. a phone clock that is ahead).
final class Invalid extends Failure {
  const Invalid({required this.code, required this.detail});
  final String code;
  final String detail;
}

/// A downloaded model did not match its published sha256.
final class ChecksumMismatch extends Failure {
  const ChecksumMismatch();
}

/// The on-device model could not be loaded; the bundled one is used instead.
final class ModelLoadFailed extends Failure {
  const ModelLoadFailed(this.detail);
  final String detail;
}

/// Anything else. Details stay in the local log; the user sees the reference.
final class Unexpected extends Failure {
  const Unexpected(this.error, {this.requestId});
  final Object error;
  final String? requestId;
}
