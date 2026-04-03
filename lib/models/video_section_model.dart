// lib/models/video_section_model.dart

class VideoSectionModel {
  String? doc_id, aid, qid, question, filename;

  VideoSectionModel({
    this.doc_id,
    this.aid,
    this.qid,
    this.question,
    this.filename,
  });

  factory VideoSectionModel.fromJson(Map<String, dynamic> json) {
    return VideoSectionModel(
      doc_id:   json["doc_id"]   ?? '',
      aid:      json["aid"]      ?? '',
      qid:      json["qid"]      ?? '',
      question: json["question"] ?? '',
      filename: json["filename"] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "doc_id":   doc_id,
      "aid":      aid,
      "qid":      qid,
      "question": question,
      "filename": filename,
    };
  }
}