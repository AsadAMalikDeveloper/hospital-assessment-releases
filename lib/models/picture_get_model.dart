class PicturesSectionModel {
  String? doc_id, aid, qid, question,bytes_data;

  PicturesSectionModel({this.doc_id, this.aid, this.qid, this.question,this.bytes_data});

  factory PicturesSectionModel.fromJson(Map<String, dynamic> json) {
    return PicturesSectionModel(
      doc_id: json["doc_id"] ?? '',
      aid: json["aid"] ?? '',
      qid: json["qid"] ?? '',
      bytes_data: json["bytes_data"] ?? '',
      question: json["question"] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "doc_id": doc_id,
      "aid": aid,
      "qid": qid,
      "bytes_data": bytes_data,
      "question": question,
    };
  }
//
}
