class BedCapacityModel {
  String? id,
      assessment_id,
      sp_id,
      criteria_type_id,
      question,
      q_id,
      section_id;
  int? male, female;

  BedCapacityModel(
      {this.id,
      this.assessment_id,
      this.sp_id,
      this.criteria_type_id,
      this.question,
      this.q_id,
      this.section_id,
      this.male,
      this.female});

  factory BedCapacityModel.fromJson(Map<String, dynamic> json) {
    return BedCapacityModel(
      id: json["id"] ?? "",
      assessment_id: json["assessment_id"] ?? "",
      sp_id: json["sp_id"] ?? "",
      criteria_type_id: json["criteria_type_id"] ?? "",
      question: json["question"] ?? "",
      q_id: json["q_id"] ?? "",
      section_id: json["section_id"] ?? "",
      male: json["male"] ?? 0,
      female: json["female"] ?? 0,
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
      "male": male,
      "female": female,
    };
  }

}
