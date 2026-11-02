import 'package:leafcheck/core/mock/mock_scenario.dart';
import 'package:leafcheck/core/result/failure.dart';
import 'package:leafcheck/core/result/result.dart';
import 'package:leafcheck/features/advice/domain/advice.dart';

/// Canned answer from the design (S4-C), after 3 s. Offline and advice-down
/// scenarios fail the way the real adapter will.
class MockAdviceRepository implements AdviceRepository {
  MockAdviceRepository(
    this.scenario, {
    this.delay = const Duration(seconds: 3),
  });

  final MockScenario scenario;
  final Duration delay;

  static const answer = AdviceAnswer(
    text:
        'Remove and destroy infected plants and leaves today [1]. '
        'Do not leave cull piles near the field [2]. '
        'In cool, wet weather, apply a protectant fungicide every 7–10 days '
        'and follow the label [1]. '
        'Check the rest of the field daily for new spots [1].',
    citations: [
      Citation(
        n: 1,
        title: 'Potato late blight',
        publisher: 'UC IPM · ipm.ucanr.edu',
        url: 'https://ipm.ucanr.edu/agriculture/potato/late-blight/',
      ),
      Citation(
        n: 2,
        title: 'Potato late blight: Management',
        publisher: 'UC IPM · ipm.ucanr.edu',
        url: 'https://ipm.ucanr.edu/agriculture/potato/late-blight/',
      ),
    ],
    grounded: true,
  );

  @override
  Future<Result<AdviceAnswer>> ask(String question, String classLabel) async {
    if (scenario == MockScenario.offline) return const Err(Offline());
    await Future<void>.delayed(delay);
    if (scenario == MockScenario.adviceDown) {
      return const Err(
        ServerUnavailable(
          code: 'advice_unavailable',
          requestId: 'd6720fce7b6a40bc496d3415f0a44062',
        ),
      );
    }
    return const Ok(answer);
  }
}
