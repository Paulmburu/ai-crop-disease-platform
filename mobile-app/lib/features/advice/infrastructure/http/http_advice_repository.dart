import 'package:dio/dio.dart';
import 'package:leafcheck/core/result/result.dart';
import 'package:leafcheck/features/advice/domain/advice.dart';
import 'package:leafcheck/shared/http/api_client.dart';

/// `POST /api/v1/advice` (go-backend → rag-service). The local LLM can take
/// a while on a cold start, hence the long receive timeout.
class HttpAdviceRepository implements AdviceRepository {
  HttpAdviceRepository(this.api);
  final ApiClient api;

  @override
  Future<Result<AdviceAnswer>> ask(String question, String classLabel) async {
    final r = await api.guard(
      () => api.dio.post<Map<String, dynamic>>(
        '/api/v1/advice',
        data: {'question': question, 'class_name': classLabel},
        options: Options(receiveTimeout: const Duration(seconds: 90)),
      ),
    );
    return switch (r) {
      Err(:final failure) => Err(failure),
      Ok(:final value) => Ok(parse(value.data!)),
    };
  }

  /// Keeps only the sources the answer cites, numbered as in the text.
  static AdviceAnswer parse(Map<String, dynamic> j) {
    final text = j['answer'] as String;
    final cited = RegExp(
      r'\[(\d+)\]',
    ).allMatches(text).map((m) => int.parse(m.group(1)!)).toSet();
    final sources = (j['sources'] as List? ?? const [])
        .cast<Map<String, dynamic>>();
    return AdviceAnswer(
      text: text,
      grounded: j['grounded'] as bool? ?? false,
      citations: [
        for (final s in sources)
          if (cited.contains(s['index'])) _citation(s),
      ],
    );
  }

  static Citation _citation(Map<String, dynamic> s) {
    final refs = (s['references'] as List? ?? const []).cast<String>();
    final url = refs.isEmpty ? '' : refs.first;
    final section = s['section'] as String?;
    final title = s['title'] as String;
    return Citation(
      n: s['index'] as int,
      title: section == null || section == 'Overview'
          ? title
          : '$title: $section',
      publisher: url.isEmpty ? '' : Uri.parse(url).host,
      url: url,
    );
  }
}
