/// Copy for the three onboarding pages (S8).
abstract final class OnboardingStrings {
  static const skip = 'Skip';
  static const next = 'Next';
  static const start = 'Start scanning';
  static const offlineTitle = 'Works in the field, without internet';
  static const offlineBody =
      'Diagnosis happens on your phone. Results are saved and synced later.';
  static const photoTitle = 'One leaf, daylight, steady';
  static const photoBody =
      'Fill the frame with one leaf. Avoid shadows and blur.';
  static const good = 'Good';
  static const hardToRead = 'Hard to read';
  static const privacyTitle = 'Your photos stay with you';
  static const privacyBody =
      'You can change the server in Settings at any time.';
  static const privacyPhotos = 'Photos stay on your phone';
  static const privacySync = 'Only the result is synced, never the photo';
  static const privacyAccount = 'No account needed';
  static String page(int n, int of) => 'Page $n of $of';
}
