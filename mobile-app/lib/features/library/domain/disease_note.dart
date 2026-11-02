/// One offline note per class the model predicts (bundled copies of
/// `rag-service/knowledge/*.md`).
class DiseaseNote {
  const DiseaseNote({
    required this.classLabel,
    required this.title,
    required this.sources,
    required this.sections,
  });

  /// Same label as the model, e.g. `Potato___Late_blight`.
  final String classLabel;
  final String title;
  final List<String> sources;

  /// Headings in file order ("Overview", "Symptoms", …) with their text.
  final List<({String heading, String body})> sections;

  String? section(String heading) =>
      sections.where((s) => s.heading == heading).firstOrNull?.body;
}

abstract interface class DiseaseLibrary {
  Future<List<DiseaseNote>> all();
}
