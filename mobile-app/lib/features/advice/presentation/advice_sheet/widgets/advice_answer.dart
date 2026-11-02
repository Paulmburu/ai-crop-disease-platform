import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:leafcheck/features/advice/domain/advice.dart';
import 'package:leafcheck/features/advice/presentation/strings/advice_strings.dart';
import 'package:leafcheck/ui/theme/app_icons.dart';
import 'package:leafcheck/ui/theme/motion.dart';
import 'package:leafcheck/ui/theme/tokens.dart';
import 'package:url_launcher/url_launcher.dart';

/// S4-C: answer text with tappable `[n]` markers, sources, disclaimer.
/// Tapping a marker scrolls to its source and highlights it for 600 ms.
class AdviceAnswerView extends StatefulWidget {
  const AdviceAnswerView(this.answer, {super.key});
  final AdviceAnswer answer;

  @override
  State<AdviceAnswerView> createState() => _AdviceAnswerViewState();
}

class _AdviceAnswerViewState extends State<AdviceAnswerView> {
  late final _keys = {
    for (final c in widget.answer.citations) c.n: GlobalKey(),
  };
  int? _highlighted;

  Future<void> _jump(int n) async {
    final ctx = _keys[n]?.currentContext;
    if (ctx == null) return;
    setState(() => _highlighted = n);
    await Scrollable.ensureVisible(
      ctx,
      duration: ReduceMotion.duration(context, AppMotion.medium),
      alignment: 0.5,
    );
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (mounted) setState(() => _highlighted = null);
  }

  /// Splits "text [1] more [2]" into text spans and marker chips.
  List<InlineSpan> _spans(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final spans = <InlineSpan>[];
    final re = RegExp(r'\s?\[(\d+)\]');
    var last = 0;
    for (final m in re.allMatches(widget.answer.text)) {
      spans.add(TextSpan(text: widget.answer.text.substring(last, m.start)));
      final n = int.parse(m.group(1)!);
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Semantics(
            button: true,
            label: 'Source $n',
            child: GestureDetector(
              onTap: () => _jump(n),
              child: Container(
                width: 20,
                height: 20,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
                child: Text(
                  '$n',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: c.onPrimaryContainer,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      last = m.end;
    }
    spans.add(TextSpan(text: widget.answer.text.substring(last)));
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = Theme.of(context).colorScheme;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: ReduceMotion.duration(context, AppMotion.medium),
      builder: (_, v, child) => Opacity(opacity: v, child: child),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(TextSpan(style: t.bodyLarge, children: _spans(context))),
          const SizedBox(height: AppSpace.xl),
          Text(AdviceStrings.sources, style: t.titleMedium),
          const SizedBox(height: AppSpace.sm),
          for (final s in widget.answer.citations)
            Padding(
              key: _keys[s.n],
              padding: const EdgeInsets.only(bottom: AppSpace.sm),
              child: _SourceRow(citation: s, highlighted: _highlighted == s.n),
            ),
          const SizedBox(height: AppSpace.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(AppIcons.info, size: 16, color: c.onSurfaceVariant),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Text(
                  AdviceStrings.disclaimer,
                  style: t.bodySmall?.copyWith(color: c.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SourceRow extends StatelessWidget {
  const _SourceRow({required this.citation, required this.highlighted});
  final Citation citation;
  final bool highlighted;

  Future<void> _open(BuildContext context) async {
    final uri = Uri.parse(citation.url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) await Clipboard.setData(ClipboardData(text: citation.url));
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return AnimatedContainer(
      duration: ReduceMotion.duration(context, AppMotion.medium),
      decoration: BoxDecoration(
        color: highlighted ? c.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.field),
        border: Border.all(color: c.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.field),
        onTap: () => _open(context),
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.md),
          child: Row(
            children: [
              Icon(AppIcons.source, color: c.onSurfaceVariant),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${citation.n}  ${citation.title}',
                      style: t.titleSmall,
                    ),
                    Text(
                      citation.publisher,
                      style: t.bodySmall?.copyWith(
                        color: c.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(AppIcons.openExternal, size: 20, color: c.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
