class SectionModelOffline {
  String? id, type_id, list_title;
  List<QuestionModelOffline>? questions;
  List<SectionChildModelOffline>? child;

  SectionModelOffline(
      {this.id, this.type_id, this.list_title, this.questions, this.child});

  factory SectionModelOffline.fromJson(Map<String, dynamic> json) {
    return SectionModelOffline(
      id: json["id"] ?? '',
      type_id: json["type_id"] ?? '',
      list_title: json["list_title"] ?? '',
      questions: json["questions"] != null
          ? (json["questions"] as List).map((x) => QuestionModelOffline.fromJson(x)).toList()
          : [],
      child: json["child"] != null
          ? (json["child"] as List).map((x) => SectionChildModelOffline.fromJson(x)).toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "type_id": type_id,
      "list_title": list_title,
      "questions":
          questions != null ? questions!.map((x) => x.toJson()).toList() : [],
      "child": child != null ? child!.map((x) => x.toJson()).toList() : [],
    };
  }
}

class OptionModelOffline {
  final String id;
  final String description;

  OptionModelOffline({required this.id, required this.description});

  factory OptionModelOffline.fromJson(Map<String, dynamic> json) {
    return OptionModelOffline(
      id: json["id"] ?? "",
      description: json["description"] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "description": description,
    };

  }
}

class QuestionModelOffline {
  String? q_id,
      description,
      question_type_id,
      question_type,
      response,
      response_ids;
  int? f_index;
  List<OptionModelOffline>? options;

  QuestionModelOffline({
    this.q_id,
    this.description,
    this.question_type_id,
    this.question_type,
    this.response,
    this.response_ids,
    this.f_index,
    this.options,
  });

  factory QuestionModelOffline.fromJson(Map<String, dynamic> json) {
    return QuestionModelOffline(
      q_id: json["q_id"] ?? "",
      description: json["description"] ?? "",
      question_type_id: json["question_type_id"] ?? "",
      question_type: json["question_type"] ?? "",
      response: json["response"] ?? "",
      response_ids: json["response_ids"] ?? "",
      f_index: json["f_index"] ?? -1,
      options: json["options"] != null
          ? (json["options"] as List).map((x) => OptionModelOffline.fromJson(x)).toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "q_id": q_id,
      "description": description,
      "question_type_id": question_type_id,
      "question_type": question_type,
      "response": response,
      "response_ids": response_ids,
      "f_index": f_index,
      "options":
          options != null ? options!.map((x) => x.toJson()).toList() : [],
    };
  }
}

class SectionChildModelOffline {
  String? id, list_title;
  List<QuestionModelOffline>? questions;

  SectionChildModelOffline({this.id, this.list_title, this.questions});

  factory SectionChildModelOffline.fromJson(Map<String, dynamic> json) {
    return SectionChildModelOffline(
      id: json["id"] ?? '',
      list_title: json["list_title"] ?? '',
      questions: json["questions"] != null
          ? List<QuestionModelOffline>.from((json["questions"] as List).map(
              (x) =>
                  QuestionModelOffline.fromJson(Map<String, dynamic>.from(x))))
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "list_title": list_title,
      "questions":
          questions != null ? questions!.map((x) => x.toJson()).toList() : [],
    };
  }
}
