import 'package:leafcheck/features/library/domain/disease_note.dart';

/// Reads the bundled knowledge notes. [load] returns a file's text (the
/// asset bundle in the app, a map in tests).
class AssetDiseaseLibrary implements DiseaseLibrary {
  AssetDiseaseLibrary(this.load);

  final Future<String> Function(String path) load;

  static const files = [
    'assets/knowledge/potato_late_blight.md',
    'assets/knowledge/potato_early_blight.md',
    'assets/knowledge/potato_healthy.md',
  ];

  List<DiseaseNote>? _cache;

  @override
  Future<List<DiseaseNote>> all() async =>
      _cache ??= [for (final f in files) parse(await load(f))];

  /// Front matter (`key: value`) + `# Title` + `## Section` blocks.
  static DiseaseNote parse(String text) {
    final lines = text.split('\n');
    final meta = <String, String>{};
    var i = 0;
    if (lines.first.trim() == '---') {
      for (i = 1; i < lines.length && lines[i].trim() != '---'; i++) {
        final at = lines[i].indexOf(':');
        if (at > 0) {
          meta[lines[i].substring(0, at).trim()] = lines[i]
              .substring(at + 1)
              .trim();
        }
      }
      i++;
    }
    var title = '';
    final sections = <({String heading, String body})>[];
    String? heading;
    final buf = StringBuffer();
    void flush() {
      if (heading != null) {
        sections.add((heading: heading, body: buf.toString().trim()));
      }
      buf.clear();
    }

    for (; i < lines.length; i++) {
      final l = lines[i];
      if (l.startsWith('## ')) {
        flush();
        heading = l.substring(3).trim();
      } else if (l.startsWith('# ')) {
        title = l.substring(2).trim();
      } else if (heading != null) {
        buf.writeln(l);
      }
    }
    flush();
    return DiseaseNote(
      classLabel: meta['class_name'] ?? '',
      title: title,
      sources: (meta['sources'] ?? '')
          .split('|')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList(),
      sections: sections,
    );
  }
}
