class CriteriaTypeModel {
  String? description,criteria_type_id;

  CriteriaTypeModel({this.description, this.criteria_type_id});

  factory CriteriaTypeModel.fromJson(Map<String, dynamic> json) {
    return CriteriaTypeModel(
      description: json["description"] ?? '',
      criteria_type_id: json["criteria_type_id"] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "description": description,
      "criteria_type_id": criteria_type_id,
    };
  }
//
}
