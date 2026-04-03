class LoginModel {
  String? status, message, username, name, token, zone_code,s_id,emp_type;

  LoginModel({
    this.status,
    this.message,
    this.username,
    this.name,
    this.token,
    this.zone_code,this.s_id,this.emp_type
  });

  factory LoginModel.fromJson(Map<String, dynamic> json) => LoginModel(
        status: json["status"] ?? "",
        message: json["message"] ?? "",
        username: json["username"] ?? "",
        name: json["name"] ?? "",
        token: json["token"] ?? "",
        zone_code: json["zone_code"] ?? "",
        s_id: json["s_id"] ?? "",
        emp_type: json["emp_type"] ?? "",
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "message": message,
        "username": username,
        "name": name,
        "token": token,
        "zone_code": zone_code,
        "s_id": s_id,
        "emp_type": emp_type,
      };
}
