
import '../models/api_response_model.dart';
import '../models/assessment_hospital_model.dart';
import 'db_helper.dart';

class AssessmentService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<List<HospitalAssessmentModel>> getAssessmentsWithSections() async {
    APIResponse<List<HospitalAssessmentModel>> assessmentsData =
        await _dbHelper.getALLItemListAssessment();
    //final sectionsData = await _dbHelper.getAllSections();

    // Map<String, List<Section>> sectionsByAssessment = {};
    //
    // for (var section in sectionsData) {
    //   String assessmentId = section['assessment_id'];
    //   if (!sectionsByAssessment.containsKey(assessmentId)) {
    //     sectionsByAssessment[assessmentId] = [];
    //   }
    //   sectionsByAssessment[assessmentId]!.add(Section(
    //     sectionId: section['section_id'],
    //     data: section['data'],
    //     isSynced: section['isSynced'] == 1,
    //   ));
    // }

    List<HospitalAssessmentModel> assessments =
        assessmentsData.data1!.map((assessment) {
      return assessment;
    }).toList();

    return assessments;
  }
}
