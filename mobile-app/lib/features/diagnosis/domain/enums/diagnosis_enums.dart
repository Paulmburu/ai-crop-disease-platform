/// The classes the potato model recognises.
enum DiagnosisCondition {
  earlyBlight('Potato___Early_blight'),
  lateBlight('Potato___Late_blight'),
  healthy('Potato___healthy')
  ;

  const DiagnosisCondition(this.label);

  /// The model's class label (same string as the server and the .json).
  final String label;

  static DiagnosisCondition fromLabel(String label) => values.firstWhere(
    (c) => c.label == label,
    orElse: () => throw ArgumentError.value(label, 'label', 'unknown class'),
  );
}

/// Same rule as the server: top-1 below the threshold means "not sure".
enum DiagnosisStatus { confident, uncertain }

/// Where a prediction was computed.
enum PredictionSource { onDevice, server }
