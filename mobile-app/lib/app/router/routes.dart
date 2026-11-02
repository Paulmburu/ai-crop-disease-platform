/// Route paths. Pages never hardcode paths.
abstract final class Routes {
  static const scan = '/scan';
  static const analyzing = '/scan/analyzing';
  static const history = '/history';
  static const settings = '/settings';
  static const model = '/settings/model';
  static const diagnostics = '/settings/diagnostics';
  static const speedTest = '/settings/diagnostics/speed';
  static const devComponents = '/dev/components';
  static const onboarding = '/onboarding';
  static const library = '/library';
  static const diseasePattern = '/library/:label';
  static String disease(String label) => '/library/$label';

  static const _diagnosis = '/diagnosis';
  static const diagnosisPattern = '$_diagnosis/:id';
  static String diagnosis(String id) => '$_diagnosis/$id';
}
