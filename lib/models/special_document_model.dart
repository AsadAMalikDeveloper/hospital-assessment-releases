import 'package:hospital_assessment_slic/models/staff_model.dart';

import 'bed_capacity_model.dart';

class OptionsSD {
  String? option_description;

  OptionsSD({this.option_description});

  factory OptionsSD.fromJson(Map<String, dynamic> json) {
    return OptionsSD(
      option_description: json["option_description"],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "option_description": option_description,
    };
  }
}

class QuestionsSD {
  String? question, question_type,selected;
  int? question_type_id;
  List<OptionsSD>? options;

  QuestionsSD(
      {this.question, this.question_type,this.selected, this.question_type_id, this.options});

  factory QuestionsSD.fromJson(Map<String, dynamic> json) {
    return QuestionsSD(
      question: json["question"]??"",
      question_type: json["question_type"]??"",
      selected: json["selected"]??"",
      question_type_id: json["question_type_id"]??-1,
      options: json["options"] != null
          ? (json["options"] as List).map((x) => OptionsSD.fromJson(x)).toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "question": question,
      "question_type": question_type,
      "selected": selected,
      "question_type_id": question_type_id,
      "options":
          options != null ? options!.map((x) => x.toJson()).toList() : [],
    };
  }
}

class SectionSD {
  String? section_name,section_id;
  List<QuestionsSD>? questions;

  SectionSD({this.section_name,this.section_id, this.questions});

  factory SectionSD.fromJson(Map<String, dynamic> json) {
    return SectionSD(
      section_name: json["section_name"]??"",
      section_id: json["section_id"]??"",
      questions: json["questions"] != null
          ? (json["questions"] as List)
              .map((x) => QuestionsSD.fromJson(x))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "section_name": section_name,
      "section_id": section_id,
      "questions":
          questions != null ? questions!.map((x) => x.toJson()).toList() : [],
    };
  }
}

class SpecialDocumentModel {
  List<BedCapacityModel>? BED;
  List<StaffModel>? STAFF;
  List<SectionSD>? SECTIONS;

  SpecialDocumentModel({this.BED, this.STAFF, this.SECTIONS});

  factory SpecialDocumentModel.fromJson(Map<String, dynamic> json) {
    return SpecialDocumentModel(
      BED: json["BED"] != null
          ? (json["BED"] as List)
              .map((x) => BedCapacityModel.fromJson(x))
              .toList()
          : [],
      STAFF: json["STAFF"] != null
          ? (json["STAFF"] as List).map((x) => StaffModel.fromJson(x)).toList()
          : [],
      SECTIONS: json["SECTIONS"] != null
          ? (json["SECTIONS"] as List)
              .map((x) => SectionSD.fromJson(x))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "BED": BED != null ? BED!.map((x) => x.toJson()).toList() : [],
      "STAFF": STAFF != null ? STAFF!.map((x) => x.toJson()).toList() : [],
      "SECTIONS":
          SECTIONS != null ? SECTIONS!.map((x) => x.toJson()).toList() : [],
    };
  }
//
}
