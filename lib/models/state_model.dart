class StateModel {
  String? state, state_ID;

  StateModel({this.state, this.state_ID});

  factory StateModel.fromJson(Map<String, dynamic> json) {
    return StateModel(
      state: json["state"] ?? "",
      state_ID: json["state_ID"] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "state": state,
      "state_ID": state_ID,
    };
  }

}
