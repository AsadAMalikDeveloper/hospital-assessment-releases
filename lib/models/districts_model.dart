class DistrictModel {
  String? district, state_id; int? district_id;

  DistrictModel({this.district,this.state_id, this.district_id});

  factory DistrictModel.fromJson(Map<String, dynamic> json) {
    return DistrictModel(
      district: json["district"] ?? "",
      state_id: json["state_id"] ?? "",
      district_id: json["district_id"] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "district": district,
      "state_id": state_id,
      "district_id": district_id,
    };
  }
}
