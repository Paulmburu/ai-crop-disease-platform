import 'package:flutter/material.dart';
import 'package:leafcheck/features/advice/presentation/strings/advice_strings.dart';
import 'package:leafcheck/ui/theme/app_icons.dart';
import 'package:leafcheck/ui/theme/diagnosis_tone.dart';
import 'package:leafcheck/ui/theme/tokens.dart';
import 'package:leafcheck/ui/widgets/diagnosis/diagnosis_chip.dart';
import 'package:leafcheck/ui/widgets/feedback/skeleton_lines.dart';

/// Diagnosis chip + close button at the top of the sheet.
class SheetHeader extends StatelessWidget {
  const SheetHeader({required this.tone, required this.label, super.key});
  final DiagnosisTone tone;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      DiagnosisChip(tone: tone, label: label),
      const Spacer(),
      IconButton(
        tooltip: AdviceStrings.close,
        icon: const Icon(AppIcons.close),
        onPressed: () => Navigator.pop(context),
      ),
    ],
  );
}

/// S4-A: outlined rows with an arrow, one per suggested question.
class SuggestedQuestions extends StatelessWidget {
  const SuggestedQuestions({required this.onAsk, super.key});
  final ValueChanged<String> onAsk;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Column(
      children: [
        for (final q in AdviceStrings.suggestions)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.md),
            child: Material(
              color: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.field),
                side: BorderSide(color: c.outlineVariant),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => onAsk(q),
                child: SizedBox(
                  height: 56,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpace.lg,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            q,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                        Icon(AppIcons.arrowForward, color: c.onSurface),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// The asked question, right-aligned (S4-B/C).
class QuestionBubble extends StatelessWidget {
  const QuestionBubble(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerRight,
    child: Container(
      constraints: const BoxConstraints(maxWidth: 300),
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
    ),
  );
}

/// S4-B: skeleton lines + how long it may take.
class AdviceLoading extends StatelessWidget {
  const AdviceLoading({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SkeletonLines(),
        const SizedBox(height: AppSpace.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              child: Text(
                AdviceStrings.waiting,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: c.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Text field pinned to the bottom of the sheet with a send button.
class AdviceInput extends StatefulWidget {
  const AdviceInput({
    required this.onSend,
    this.enabled = true,
    this.followUp = false,
    super.key,
  });

  final ValueChanged<String> onSend;
  final bool enabled;
  final bool followUp;

  @override
  State<AdviceInput> createState() => _AdviceInputState();
}

class _AdviceInputState extends State<AdviceInput> {
  final _c = TextEditingController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _send() {
    final q = _c.text.trim();
    if (q.isEmpty) return;
    _c.clear();
    widget.onSend(q);
  }

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: widget.enabled ? 1 : 0.38,
    child: TextField(
      controller: _c,
      enabled: widget.enabled,
      textInputAction: TextInputAction.send,
      onSubmitted: (_) => _send(),
      maxLength: 500,
      buildCounter:
          (_, {required currentLength, required isFocused, maxLength}) => null,
      decoration: InputDecoration(
        hintText: widget.followUp
            ? AdviceStrings.followUpHint
            : AdviceStrings.inputHint,
        suffixIcon: IconButton(
          tooltip: AdviceStrings.send,
          icon: Icon(
            AppIcons.send,
            color: Theme.of(context).colorScheme.primary,
          ),
          onPressed: widget.enabled ? _send : null,
        ),
      ),
    ),
  );
}
