import 'package:leafcheck/features/library/domain/disease_note.dart';

class GetDiseaseNotes {
  const GetDiseaseNotes(this.library);
  final DiseaseLibrary library;
  Future<List<DiseaseNote>> call() => library.all();
}
