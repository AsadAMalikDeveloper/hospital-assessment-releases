class HospitalModel {
  String? hospital, sp_id;
  int? dist_id;

  HospitalModel({this.hospital, this.sp_id,this.dist_id});

  factory HospitalModel.fromJson(Map<String, dynamic> json) {
    return HospitalModel(
      hospital: json["hospital"] ?? "",
      sp_id: json["sp_id"] ?? "",
      dist_id: json["dist_id"] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "hospital": hospital,
      "sp_id": sp_id,
      "dist_id": dist_id,
    };
  }
}
