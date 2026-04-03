class StaffModel {
  String? id,
      assessment_id,
      sp_id,
      criteria_type_id,
      question,
      q_id,
      section_id;
  int? full_time, part_time;

  StaffModel(
      {this.id,
      this.assessment_id,
      this.sp_id,
      this.criteria_type_id,
      this.question,
      this.q_id,
      this.section_id,
      this.full_time,
      this.part_time});

  factory StaffModel.fromJson(Map<String, dynamic> json) {
    return StaffModel(
      id: json["id"] ?? "",
      assessment_id: json["assessment_id"] ?? "",
      sp_id: json["sp_id"] ?? "",
      criteria_type_id: json["criteria_type_id"] ?? "",
      question: json["question"] ?? "",
      q_id: json["q_id"] ?? "",
      section_id: json["section_id"] ?? "",
      full_time: json["full_time"] ?? 0,
      part_time: json["part_time"] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "assessment_id": assessment_id,
      "sp_id": sp_id,
      "criteria_type_id": criteria_type_id,
      "question": question,
      "q_id": q_id,
      "section_id": section_id,
      "full_time": full_time,
      "part_time": part_time,
    };
  }
}
