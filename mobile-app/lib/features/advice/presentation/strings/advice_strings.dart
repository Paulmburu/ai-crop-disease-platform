/// Copy for the advice sheet (S4).
abstract final class AdviceStrings {
  static String title(String condition) =>
      'Ask about ${condition.toLowerCase()}';
  static const subtitle =
      'Answers come from extension guides and list their sources.';
  static const inputHint = 'Type your question';
  static const followUpHint = 'Ask a follow-up';
  static const send = 'Send';
  static const close = 'Close';
  static const waiting =
      'Looking through the guides… this can take up to 20 seconds';
  static const sources = 'Sources';
  static const disclaimer =
      'Learning notes, not professional advice. Follow local guidance and '
      'pesticide labels.';
  static const offlineTitle = 'Advice needs internet';
  static const offlineBody =
      "Your diagnosis is saved. We'll ask as soon as you're back online.";
  static const askWhenOnline = 'Ask when online';
  static const queued = "Saved. We'll ask when you're back online.";
  static const unavailableTitle = 'Advice is unavailable right now';
  static const unavailableBody =
      "The advice service isn't responding. Try again in a few minutes.";
  static const tooShort = 'Questions need at least 3 characters.';

  /// Suggested questions (S4-A).
  static const suggestions = [
    'What should I do today?',
    'How does it spread?',
    'How do I prevent it next season?',
  ];
}
