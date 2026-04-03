class HospitalAssessmentModel {
  int? criteria_level;
  String? assessment_id,
      hospital,
      sp_id,
      criteria_type_id,
      criteria,
      assessment_status,
      assessment_detail,
      completion_date,
      action;
  num? score, total;

  HospitalAssessmentModel(
      {this.assessment_id,
      this.sp_id,
      this.criteria_type_id,
      this.criteria_level,
      this.hospital,
      this.criteria,
      this.assessment_status,
      this.assessment_detail,
      this.completion_date,
      this.action,
      this.score,
      this.total});

  factory HospitalAssessmentModel.fromJson(Map<String, dynamic> json) {
    return HospitalAssessmentModel(
      assessment_id: json["assessment_id"] ?? '',
      sp_id: json["sp_id"] ?? '',
      criteria_type_id: json["criteria_type_id"] ?? '',
      criteria_level: json["criteria_level"] ?? -1,
      hospital: json["hospital"] ?? "",
      criteria: json["criteria"] ?? "",
      assessment_status: json["assessment_status"] ?? "",
      assessment_detail: json["assessment_detail"] ?? "",
      completion_date: json["completion_date"] ?? "",
      action: json["action"] ?? "",
      score: json["score"] ?? 0,
      total: json["total"] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "assessment_id": assessment_id,
      "sp_id": sp_id,
      "criteria_type_id": criteria_type_id,
      "criteria_level": criteria_level,
      "hospital": hospital,
      "criteria": criteria,
      "assessment_status": assessment_status,
      "assessment_detail": assessment_detail,
      "completion_date": completion_date,
      "action": action,
      "score": score,
      "total": total,
    };
  }
//
}
