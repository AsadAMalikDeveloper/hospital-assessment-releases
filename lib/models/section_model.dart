

class SectionModel {
  String? id, type_id, list_title;
  List<Question>? questions;
  List<SectionChildModel>? child;

  SectionModel({
    this.id,
    this.type_id,
    this.list_title,
    this.questions,
    this.child,
  });

  factory SectionModel.fromJson(Map<String, dynamic> json) {
    return SectionModel(
      id: json["id"] ?? '',
      type_id: json["type_id"] ?? '',
      list_title: json["list_title"] ?? '',
      questions: json["questions"] != null
          ? List<Question>.from((json["questions"] as List)
              .map((x) => Question.fromJson(Map<String, dynamic>.from(x))))
          : [],
      child: json["child"] != null
          ? List<SectionChildModel>.from((json["child"] as List).map(
              (x) => SectionChildModel.fromJson(Map<String, dynamic>.from(x))))
          : [],
      // questions: json["questions"] != null
      //     ? List<Question>.from(
      //         json["questions"].map((x) => Question.fromJson(x)))
      //     : [],
      // child: json["child"] != null
      //     ? List<SectionChildModel>.from(
      //         json["child"].map((x) => SectionChildModel.fromJson(x)))
      //     : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "type_id": type_id,
      "list_title": list_title,
      "questions": questions != null
          ? List<dynamic>.from(questions!.map((x) => x.toJson()))
          : [],
      "child": child != null
          ? List<dynamic>.from(child!.map((x) => x.toJson()))
          : [],

      // "questions": questions != null ? questions!.map((x) => x.toJson()).toList() : [],
      // "child": child != null ? child!.map((x) => x.toJson()).toList() : [],
    };
  }
}

class Question {
  String? q_id,
      description,
      question_type_id,
      question_type,
  file_type,
      response,
      response_ids;
  int? f_index;
  List<Option>? options;

  Question({
    this.q_id,
    this.description,
    this.question_type_id,
    this.question_type,
    this.file_type,
    this.response,
    this.response_ids,
    this.f_index,
    this.options,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      q_id: json["q_id"] ?? "",
      description: json["description"] ?? "",
      question_type_id: json["question_type_id"] ?? "",
      question_type: json["question_type"] ?? "",
      file_type: json["file_type"] ?? "",
      response: json["response"] ?? "",
      response_ids: json["response_ids"] ?? "",
      f_index: json["f_index"] ?? -1,
      // options: json["options"] != null
      //     ? List<Option>.from(json["options"].map((x) => Option.fromJson(x)))
      //     : [],
      options: json["options"] != null
          ? List<Option>.from((json["options"] as List)
              .map((x) => Option.fromJson(Map<String, dynamic>.from(x))))
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "q_id": q_id,
      "description": description,
      "question_type_id": question_type_id,
      "question_type": question_type,
      "file_type": file_type,
      "response": response,
      "response_ids": response_ids,
      "f_index": f_index,
      //"options": options != null ? options!.map((x) => x.toJson()).toList() : [],
      "options": options != null
          ? List<dynamic>.from(options!.map((x) => x.toJson()))
          : [],
    };
  }
}

class Option {
  final String id;
  final String description;

  Option({required this.id, required this.description});

  factory Option.fromJson(Map<String, dynamic> json) {
    return Option(
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

class SectionChildModel {
  String? id, list_title;
  List<Question>? questions;
  List<SectionChildModel>? child;

  SectionChildModel({this.id, this.list_title, this.questions, this.child});

  factory SectionChildModel.fromJson(Map<String, dynamic> json) {
    return SectionChildModel(
      id: json["id"] ?? '',
      list_title: json["list_title"] ?? "",
      // questions: json["questions"] != null
      //     ? List<Question>.from((json["questions"] as List).map((x) => Question.fromJson(Map<String, dynamic>.from(x))))
      //     : [],
      questions: json["questions"] != null
          ? List<Question>.from(
              json["questions"].map((x) => Question.fromJson(x)))
          : [],
      child: json["child"] != null
          ? List<SectionChildModel>.from((json["child"] as List).map(
              (x) => SectionChildModel.fromJson(Map<String, dynamic>.from(x))))
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "list_title": list_title,
      "questions": questions != null
          ? List<dynamic>.from(questions!.map((x) => x.toJson()))
          : [],
      "child": child != null
          ? List<dynamic>.from(child!.map((x) => x.toJson()))
          : [],
      //"questions": questions != null ? questions!.map((x) => x.toJson()).toList() : [],
    };
  }
}

// class SectionChildModel {
//   String? id, list_title;
//   List<Question>? questions;
//
//   SectionChildModel({this.id, this.list_title, this.questions});
//
//   factory SectionChildModel.fromJson(Map<String, dynamic> json) {
//     return SectionChildModel(
//         id: json["id"] ?? '',
//         list_title: json["list_title"] ?? "",
//         questions: List<Question>.from(
//             json["questions"].map((x) => Question.fromJson(x))));
//   }
//
//   Map<String, dynamic> toJson() {
//     return {
//       "id": id,
//       "list_title": list_title,
//       "questions": List<dynamic>.from(questions!.map((x) => x.toJson()))
//     };
//   }
// }
//
// class Option {
//   final String id;
//   final String description;
//
//   Option({required this.id, required this.description});
//
//   factory Option.fromJson(Map<String, dynamic> json) {
//     return Option(
//       id: json["id"] ?? "",
//       description: json["description"] ?? "",
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     return {
//       "id": id,
//       "description": description,
//     };
//   }
// }
//
// class Question {
//   String? q_id,
//       description,
//       question_type_id,
//       question_type,
//       response,
//       response_ids;
//   int? f_index;
//   List<Option>? options;
//
//   Question(
//       {this.q_id,
//       this.description,
//       this.question_type_id,
//       this.question_type,
//       this.response,
//       this.response_ids,
//       this.f_index,
//       this.options});
//
//   factory Question.fromJson(Map<String, dynamic> json) {
//     return Question(
//         q_id: json["q_id"] ?? "",
//         description: json["description"] ?? "",
//         question_type_id: json["question_type_id"] ?? "",
//         question_type: json["question_type"] ?? "",
//         response: json["response"] ?? "",
//         response_ids: json["response_ids"] ?? "",
//         f_index: json["f_index"] ?? -1,
//         options:
//             json['options']!=null?List<Option>.from(json["options"].map((x) => Option.fromJson(x))):[]);
//   }
//
//   Map<String, dynamic> toJson() {
//     return {
//       "q_id": q_id,
//       "description": description,
//       "question_type_id": question_type_id,
//       "question_type": question_type,
//       "f_index": f_index,
//       "options_main": List<dynamic>.from(options!.map((x) => x.toJson()))
//     };
//   }
// }
//
// class SectionModel {
//   String? id, type_id, list_title;
//   List<Question>? questions;
//   List<SectionChildModel>? child;
//
//   SectionModel(
//       {this.id, this.type_id, this.list_title, this.questions, this.child});
//
//   factory SectionModel.fromJson(Map<String, dynamic> json) {
//     return SectionModel(
//         id: json["id"] ?? '',
//         type_id: json["type_id"] ?? '',
//         list_title: json["list_title"] ?? '',
//         questions: List<Question>.from(
//             json["questions"].map((x) => Question.fromJson(x))),
//         child: List<SectionChildModel>.from(
//             json["child"].map((x) => SectionChildModel.fromJson(x))));
//   }
//
//   Map<String, dynamic> toJson() {
//     return {
//       "id": id,
//       "type_id": type_id,
//       "list_title": list_title,
//       "child": List<dynamic>.from(child!.map((x) => x.toJson())),
//       "questions": List<dynamic>.from(questions!.map((x) => x.toJson()))
//     };
//   }
// }
