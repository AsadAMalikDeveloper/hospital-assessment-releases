import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:hospital_assessment_slic/models/video_section_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/api_response_model.dart';
import '../models/assessment_hospital_model.dart';
import '../models/bed_capacity_model.dart';
import '../models/districts_model.dart';
import '../models/hospital_model.dart';
import '../models/picture_get_model.dart';
import '../models/section_model.dart';
import '../models/staff_model.dart';
import '../models/state_model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'assessment.db');
    return openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    // await db.execute(
    //     'CREATE TABLE states (state TEXT,state_ID TEXT,last_sync TEXT)');
    // await db.execute(
    //     'CREATE TABLE districts (district TEXT,district_id INTEGER,state_id TEXT,last_sync TEXT)');
    // await db.execute(
    //     'CREATE TABLE hospitals (hospital TEXT,sp_id TEXT,dist_id INTEGER,last_sync TEXT)');
    await db.execute('''
      CREATE TABLE assessment (
        id INTEGER PRIMARY KEY,
        assessment_data TEXT,
        section_data TEXT
      )
    ''');
    await db.execute('''
    CREATE TABLE IF NOT EXISTS bedCapacity (
    id TEXT,
      q_id TEXT PRIMARY KEY,
      assessment_id TEXT,
      sp_id TEXT,
      criteria_type_id TEXT,
      section_id TEXT,
      question TEXT,
      male INTEGER,
      female INTEGER
    )
    ''');
    await db.execute('''
    
    CREATE TABLE IF NOT EXISTS staffing (
    id TEXT,
      q_id TEXT PRIMARY KEY,
      assessment_id TEXT,
      sp_id TEXT,
      criteria_type_id TEXT,
      section_id TEXT,
      question TEXT,
      full_time INTEGER,
      part_time INTEGER
    )
    ''');

    await db.execute('''
    
    CREATE TABLE IF NOT EXISTS images (
    
      qid TEXT PRIMARY KEY,
      aid TEXT,
      doc_id TEXT,
      bytes_data TEXT
    )
    ''');

    await db.execute('''
    
    CREATE TABLE IF NOT EXISTS pdf (
      aid TEXT,
      doc_id TEXT,
      bytes_data TEXT
    )
    ''');

    // In your createTables or onCreate method, add alongside 'images' table:

    await db.execute('''
      CREATE TABLE IF NOT EXISTS videos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        aid TEXT,
        qid TEXT,
        file_path TEXT,
        is_synced INTEGER DEFAULT 0
      )
    ''');
    // await db.execute('''
    //   CREATE TABLE assessments(
    //     assessment_id TEXT PRIMARY KEY,
    //     sp_id TEXT,
    //     hospital TEXT,
    //     criteria TEXT,
    //     criteria_type_id TEXT,
    //     assessment_status TEXT,
    //     assessment_detail TEXT,
    //     score INTEGER,
    //     total INTEGER,
    //     criteria_level INTEGER,
    //     completion_date TEXT,
    //     action TEXT
    //   )
    // ''');
    // await db.execute('''
    //   CREATE TABLE section (
    //     id TEXT PRIMARY KEY,
    //     assessment_id TEXT,
    //     type_id TEXT,
    //     list_title TEXT,
    //     questions TEXT,
    //     child TEXT,
    //     FOREIGN KEY (assessment_id) REFERENCES assessments (assessment_id)
    //   )
    // ''');
  }
// Insert video path into SQLite (offline)
  Future<APIResponse> insertVideo(String aid, String qid, String filePath) async {
    try {
      final db = await database;

      // One video per question — delete existing first (mirrors deleteImage)
      await db.delete('videos',
          where: 'aid = ? AND qid = ?', whereArgs: [aid, qid]);

      await db.insert('videos', {
        'aid': aid,
        'qid': qid,
        'file_path': filePath,
        'is_synced': 0,
      });

      return APIResponse(status: 'success', message: 'Video saved locally');
    } catch (e) {
      return APIResponse(status: 'error', message: e.toString());
    }
  }

// Get all offline videos for an assessment
  Future<APIResponse<List<VideoSectionModel>>> getVideos(String aid) async {
    try {
      final db = await database;
      final maps = await db.query('videos',
          where: 'aid = ?', whereArgs: [aid]);

      return APIResponse<List<VideoSectionModel>>(
        status: 'success',
        data: maps.map((m) => VideoSectionModel(
          aid: m['aid'] as String?,
          qid: m['qid'] as String?,
          doc_id: m['file_path'] as String?, // reuse doc_id to store path
          filename: m['file_path'] as String?,
        )).toList(),
      );
    } catch (e) {
      return APIResponse(status: 'error', message: e.toString());
    }
  }

// Delete offline video
  Future<APIResponse> deleteVideo(String qid) async {
    try {
      final db = await database;
      await db.delete('videos', where: 'qid = ?', whereArgs: [qid]);
      return APIResponse(status: 'success', message: 'Deleted');
    } catch (e) {
      return APIResponse(status: 'error', message: e.toString());
    }
  }
  Future<APIResponse> insertImage(String aid, String qid, String path,String bytes) async {
    final db = await database;
    try {
      await db.insert(
        'images',
        {'doc_id': path, 'aid': aid, 'qid': qid, 'bytes_data':bytes},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return APIResponse(
          status: 'success',
          message:
              'Image Saved locally'); // Return true if insertion is successful
    } catch (e) {
      return APIResponse(
          status: 'error',
          message: e.toString()); // Return false if an error occurs
    }
  }
  Future<APIResponse> insertPDF(String aid, String path,String bytes) async {
    final db = await database;
    try {
      await db.insert(
        'pdf',
        {'doc_id': path, 'aid': aid, 'bytes_data': bytes},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return APIResponse(
          status: 'success',
          message:
              'PDF Saved locally'); // Return true if insertion is successful
    } catch (e) {
      return APIResponse(
          status: 'error',
          message: e.toString()); // Return false if an error occurs
    }
  }

  Future<APIResponse> deleteImage(String qid) async {
    final db = await database;
    try {
      await db.delete(
        'images',
        where: 'qid = ?',
        whereArgs: [qid],
      );
      return APIResponse(
          status: 'success',
          message: 'Image Deleted'); // Return true if insertion is successful
    } catch (e) {
      return APIResponse(
          status: 'error',
          message: e.toString()); // Return false if an error occurs
    }
  }

  Future<APIResponse> deletePdf(String aid) async {
    final db = await database;
    try {
      await db.delete(
        'pdf',
        where: 'aid = ?',
        whereArgs: [aid],
      );
      return APIResponse(
          status: 'success',
          message: 'PDF Deleted'); // Return true if insertion is successful
    } catch (e) {
      return APIResponse(
          status: 'error',
          message: e.toString()); // Return false if an error occurs
    }
  }

  Future<APIResponse<List<PicturesSectionModel>>> getImages() async {
    final db = await database;
    //return await db.query('images');

    List<Map<String, dynamic>> maps = await db.query('images');
    return APIResponse<List<PicturesSectionModel>>(
      data: List.generate(maps.length, (i) {
        Map<String, dynamic> item = maps[i];
        return PicturesSectionModel.fromJson(item);
      }),
    );
    //return db.query('assessments', where: 'isSynced = ?', whereArgs: [0]);
  }
  Future<APIResponse<List<PicturesSectionModel>>> getPDF() async {
    final db = await database;
    //return await db.query('images');

    List<Map<String, dynamic>> maps = await db.query('pdf');
    print('object31 ${maps.length}');
    return APIResponse<List<PicturesSectionModel>>(
      data: List.generate(maps.length, (i) {
        Map<String, dynamic> item = maps[i];
        return PicturesSectionModel.fromJson(item);
      }),
    );
    //return db.query('assessments', where: 'isSynced = ?', whereArgs: [0]);
  }

  Future<void> updateBedCapacity(String qid, int male, int female) async {
    final db = await database;

    await db.update(
      'bedCapacity',
      {'male': male, 'female': female},
      where: 'q_id = ?',
      whereArgs: [qid],
    );
  }

  Future<void> updateStaffing(String qid, int fullTime, int partTime) async {
    final db = await database;

    await db.update(
      'staffing',
      {'full_time': fullTime, 'part_time': partTime},
      where: 'q_id = ?',
      whereArgs: [qid],
    );
  }

  Future<void> insertOrUpdateBedCapacityList(BedCapacityModel model) async {
    final db = await database;

    await db.insert('bedCapacity', {
      'id': model.id,
      'q_id': model.q_id,
      'assessment_id': model.assessment_id,
      'sp_id': model.sp_id,
      'criteria_type_id': model.criteria_type_id,
      'section_id': model.section_id,
      'question': model.question,
      'male': model.male,
      'female': model.female,
    });
  }

  Future<void> insertOrUpdateStaffingList(StaffModel model) async {
    final db = await database;
    await db.insert('staffing', {
      'id': model.id,
      'q_id': model.q_id,
      'assessment_id': model.assessment_id,
      'sp_id': model.sp_id,
      'criteria_type_id': model.criteria_type_id,
      'section_id': model.section_id,
      'question': model.question,
      'full_time': model.full_time,
      'part_time': model.part_time,
    });
  }

  Future<int> addItemList(HospitalAssessmentModel hospitalAssessmentModel,
      SectionModel model) async {
    final db = await database;
    return await db.rawInsert(
      '''INSERT INTO assessment (assessment_data,section_data) VALUES (?, ?)''',
      [
        jsonEncode(hospitalAssessmentModel.toJson()),
        jsonEncode(model.toJson())
      ],
    );
  }

  Future<APIResponse<List<BedCapacityModel>>> getBedCapacity() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query('bedCapacity');
    return APIResponse<List<BedCapacityModel>>(
      data: List.generate(maps.length, (i) {
        Map<String, dynamic> item = maps[i];
        return BedCapacityModel.fromJson(item);
      }),
    );
  }

  Future<APIResponse<List<StaffModel>>> getStaffingList() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query('staffing');
    return APIResponse<List<StaffModel>>(
      data: List.generate(maps.length, (i) {
        Map<String, dynamic> item = maps[i];
        return StaffModel.fromJson(item);
      }),
    );
  }

  Future<APIResponse<List<SectionModel>>> getALLItemList() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query('assessment');
    return APIResponse<List<SectionModel>>(
      data: List.generate(maps.length, (i) {
        Map<String, dynamic> item = jsonDecode(maps[i]['section_data']);
        return SectionModel.fromJson(item);
      }),
    );
  }

  Future<APIResponse<List<HospitalAssessmentModel>>>
      getALLItemListAssessment() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query('assessment');
    return APIResponse<List<HospitalAssessmentModel>>(
      data1: List.generate(maps.length, (i) {
        Map<String, dynamic> item = jsonDecode(maps[i]['assessment_data']);
        return HospitalAssessmentModel.fromJson(item);
      }),
    );
  }

  // bool updateQuestion(dynamic data, String qId, String newResponse, String newResponseIds) {
  //   if (data == null) return false;
  //
  //   if (data is Map<String, dynamic>) {
  //     if (data.containsKey('questions')) {
  //       if (updateQuestion(data['questions'], qId, newResponse, newResponseIds)) {
  //         return true;
  //       }
  //     }
  //     if (data.containsKey('child')) {
  //       if (updateQuestion(data['child'], qId, newResponse, newResponseIds)) {
  //         return true;
  //       }
  //     }
  //   } else if (data is List) {
  //     for (var item in data) {
  //       if (item is Map<String, dynamic>) {
  //         if (item.containsKey('questions')) {
  //           if (updateQuestion(item['questions'], qId, newResponse, newResponseIds)) {
  //             return true;
  //           }
  //         } else if (item.containsKey('q_id') && item['q_id'] == qId) {
  //           item['response'] = newResponse;
  //           item['response_ids'] = newResponseIds;
  //           return true;
  //         } else if (item.containsKey('child')) {
  //           if (updateQuestion(item['child'], qId, newResponse, newResponseIds)) {
  //             return true;
  //           }
  //         }
  //       }
  //     }
  //   }
  //   return false;
  // }
  //
  // Future<void> updateQuestionInSectionData(
  //     String sectionDataId, String qId, String newResponse, String newResponseIds) async {
  //   final db = await database;
  //
  //   // Retrieve the existing section data JSON
  //   final List<Map<String, dynamic>> existingData = await db.rawQuery('''
  //   SELECT section_data FROM assessment
  //   WHERE section_data LIKE '%"id":"$sectionDataId"%'
  // ''');
  //
  //   if (existingData.isEmpty) {
  //     throw Exception('Section data with ID $sectionDataId not found.');
  //   }
  //
  //   final existingSectionDataJson = existingData.first['section_data'] as String;
  //   final existingDataParsed = jsonDecode(existingSectionDataJson);
  //
  //   print(existingSectionDataJson); // Print the JSON structure
  //
  //   // Start updating the relevant question from the root
  //   bool questionUpdated = updateQuestion(existingDataParsed, qId, newResponse, newResponseIds);
  //
  //   if (!questionUpdated) {
  //     throw Exception(
  //         'Question with ID $qId not found in section data with ID $sectionDataId.');
  //   }
  //
  //   // Convert the updated data back to JSON
  //   final updatedSectionDataJson = jsonEncode(existingDataParsed);
  //
  //   // Update the database with the new section data JSON
  //   await db.rawUpdate('''
  //   UPDATE assessment
  //   SET section_data = ?
  //   WHERE section_data LIKE '%"id":"$sectionDataId"%'
  // ''', [updatedSectionDataJson]);
  // }

  Future<void> updateQuestionInSectionData(String sectionDataId, String qId,
      String newResponse, String newResponseIds) async {
    print(
        'section ${sectionDataId} QID ${qId} R ${newResponse} rs ${newResponseIds}');
    final db = await database;

    // Retrieve the existing section data JSON
    final List<Map<String, dynamic>> existingData = await db.rawQuery('''
    SELECT section_data FROM assessment
    WHERE section_data LIKE '%"id":"$sectionDataId"%' AND 
    section_data LIKE '%"q_id":"$qId"%' 
  ''');
    print('111 ${existingData.length}');
    if (existingData.isEmpty) {
      throw Exception('Section data with ID $sectionDataId not found.');
    }

    final existingSectionDataJson =
        existingData.first['section_data'] as String;
    final existingDataParsed = jsonDecode(existingSectionDataJson);

    print(existingSectionDataJson); // Print the JSON structure

    // Start updating the relevant question from the root
    bool questionUpdated =
        updateQuestion(existingDataParsed, qId, newResponse, newResponseIds);

    if (!questionUpdated) {
      throw Exception(
          'Question with ID $qId not found in section data with ID $sectionDataId.');
    }

    // Convert the updated data back to JSON
    final updatedSectionDataJson = jsonEncode(existingDataParsed);

    // Update the database with the new section data JSON
    await db.rawUpdate('''
    UPDATE assessment
    SET section_data = ?
    WHERE section_data LIKE '%"id":"$sectionDataId"%' AND 
    section_data LIKE '%"q_id":"$qId"%' 
  ''', [updatedSectionDataJson]);
  }

  Future<void> clearAssessmentTable() async {
    final db = await database;
    await db.delete('assessment');
    await db.delete('images');
    await db.delete('bedCapacity');
    await db.delete('staffing');
    await db.delete('pdf');
    await db.delete('videos');
  }

  bool updateQuestion(Map<String, dynamic> sectionData, String qId,
      String newResponse, String newResponseIds) {
    // Check if there are questions in the current sectionData
    if (sectionData.containsKey('questions')) {
      for (var question in sectionData['questions']) {
        if (question['q_id'] == qId) {
          question['response'] = newResponse;
          question['response_ids'] = newResponseIds;
          return true;
        }
      }
    }

    // Recursively check within the child elements
    if (sectionData.containsKey('child')) {
      for (var child in sectionData['child']) {
        if (updateQuestion(child, qId, newResponse, newResponseIds)) {
          return true;
        }
      }
    }

    return false; // If the question is not found
  }

  Future<void> updateQuestionInSectionDataNew(String sectionDataId, String qId,
      String newResponse, String newResponseIds) async {
    final db = await database;

    // Retrieve the existing section data JSON
    final List<Map<String, dynamic>> existingData = await db.rawQuery('''
    SELECT section_data FROM assessment
    WHERE section_data LIKE '%"id":"$sectionDataId"%'
  ''');

    if (existingData.isEmpty) {
      throw Exception('Section data with ID $sectionDataId not found.');
    }

    final existingSectionDataJson =
        existingData.first['section_data'] as String;
    final existingDataParsed = jsonDecode(existingSectionDataJson);

    print(existingSectionDataJson); // Print the JSON structure

    // Helper function to update the question within the given list of questions
    bool updateQuestion(dynamic data) {
      print('12 ${data['questions']}  ${data['child']}');
      if (data == null) return false;

      if (data is Map<String, dynamic>) {
        if (data.containsKey('questions')) {
          return updateQuestion(data['questions']);
        }
        if (data.containsKey('child')) {
          return updateQuestion(data['child']);
        }
      } else if (data is List) {
        for (var question in data) {
          if (question['q_id'] == qId) {
            question['response'] = newResponse;
            question['response_ids'] = newResponseIds;
            return true;
          } else if (question.containsKey('child')) {
            if (updateQuestion(question['child'])) {
              return true;
            }
          }
        }
      }
      return false;
    }

    // Start updating the relevant question from the root
    bool questionUpdated = updateQuestion(existingDataParsed);

    if (!questionUpdated) {
      throw Exception(
          'Question with ID $qId not found in section data with ID $sectionDataId.');
    }

    // Convert the updated data back to JSON
    final updatedSectionDataJson = jsonEncode(existingDataParsed);

    // Update the database with the new section data JSON
    await db.rawUpdate('''
    UPDATE assessment
    SET section_data = ?
    WHERE section_data LIKE '%"id":"$sectionDataId"%'
  ''', [updatedSectionDataJson]);
  }

  // Retrieve the existing section data
  // Future<void> updateQuestionInSectionData(String sectionDataId, String qId, String newResponse, String newResponseIds) async {
  //   final db = await database;
  //
  //   // Retrieve the existing section data JSON
  //   final List<Map<String, dynamic>> existingData = await db.rawQuery('''
  //     SELECT section_data FROM assessment
  //     WHERE section_data LIKE '%"id":"$sectionDataId"%'
  //   ''');
  //
  //   if (existingData.isEmpty) {
  //     throw Exception('Section data with ID $sectionDataId not found.');
  //   }
  //
  //   final existingSectionDataJson =
  //       existingData.first['section_data'] as String;
  //   final existingDataParsed = jsonDecode(existingSectionDataJson);
  //
  //   // Update the relevant question
  //   bool questionUpdated = false;
  //   for (var question in existingDataParsed['questions']) {
  //     if (question['q_id'] == qId) {
  //       question['response'] = newResponse;
  //       question['response_ids'] = newResponseIds;
  //       questionUpdated = true;
  //       break;
  //     }
  //   }
  //
  //   if (!questionUpdated) {
  //     throw Exception(
  //         'Question with ID $qId not found in section data with ID $sectionDataId.');
  //   }
  //
  //   // Convert the updated data back to JSON
  //   final updatedSectionDataJson = jsonEncode(existingDataParsed);
  //
  //   // Update the database with the new section data JSON
  //   await db.rawUpdate('''
  //     UPDATE assessment
  //     SET section_data = ?
  //     WHERE section_data LIKE '%"id":"$sectionDataId"%'
  //   ''', [updatedSectionDataJson]);
  // }

  Future<bool> assessmentExists(
      HospitalAssessmentModel hospitalAssessmentModel) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      'assessment',
    );

    return result.isNotEmpty;
  }

  Future<void> insertStates(String state, String stateId) async {
    final db = await database;
    await db.insert('states', {
      'state': state,
      'state_ID': stateId,
      'last_sync': DateTime.now().toString(),
    });
  }

  Future<void> insertDistricts(
      String district, int disctID, String stateID) async {
    final db = await database;
    await db.insert('districts', {
      'district': district,
      'district_id': disctID,
      'state_id': stateID,
      'last_sync': DateTime.now().toString(),
    });
  }

  Future<void> insertHospitals(String hospital, String spId, int distId) async {
    final db = await database;
    await db.insert('hospitals', {
      'hospital': hospital,
      'sp_id': spId,
      'dist_id': distId,
      'last_sync': DateTime.now().toString(),
    });
  }

  Future<List<StateModel>> getAllStates() async {
    final db = await database;
    final List<Map<String, dynamic>> maps =
        await db.rawQuery('SELECT state, state_ID FROM states');

    // Convert the List<Map<String, dynamic>> to List<StateModel>
    return List.generate(maps.length, (i) {
      return StateModel.fromJson(maps[i]);
    });
  }

  Future<List<DistrictModel>> getAllDistricts(String stateID) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
        'SELECT district, district_id FROM districts WHERE state_id = ?',
        [stateID]);
    // Convert the List<Map<String, dynamic>> to List<StateModel>
    return List.generate(maps.length, (i) {
      return DistrictModel.fromJson(maps[i]);
    });
  }

  Future<List<HospitalModel>> getAllHospital(int distId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
        'SELECT hospital, sp_id FROM hospitals WHERE dist_id = ?', [distId]);
    // Convert the List<Map<String, dynamic>> to List<StateModel>
    return List.generate(maps.length, (i) {
      return HospitalModel.fromJson(maps[i]);
    });
  }

  Future<void> clearTables() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('states');
      await txn.delete('districts');
      await txn.delete('hospitals');
    });
  }
  Future<String> getDatabasePath() async {
    final dbPath = await getDatabasesPath();
    return join(dbPath, 'assessment.db');
  }
  Future<void> requestStoragePermission() async {
    var status = await Permission.accessMediaLocation.status;
    if (!status.isGranted) {
      status = await Permission.accessMediaLocation.request();
      if (!status.isGranted) {
        print('Storage permission denied.');
      }
    }
  }

  Future<void> exportDatabase() async {
    await requestStoragePermission();

    final dbPath = await getDatabasePath();
    final exportDirectory = Directory('/storage/emulated/0/Download'); // Use getApplicationDocumentsDirectory() for iOS
    final newPath = '${exportDirectory.path}/testing_${DateTime.now().microsecondsSinceEpoch}.db'; // Replace with your actual database name

    print('PATv ${exportDirectory.path} DB ${dbPath}');
    try {
      final file = File(dbPath);
      if (await file.exists()) {
        // Ensure the export directory exists
        if (!await exportDirectory.exists()) {
          await exportDirectory.create(recursive: true);
        }

        // Copy the database file to the new path
        final newFile = File(newPath);
        await file.copy(newPath);
        print('Database exported to $newPath');
        print('Database Size ${newFile.path}');
      } else {
        print('Database file does not exist.');
      }
    } catch (e) {
      print('Error exporting database: $e');
    }
  }
}
