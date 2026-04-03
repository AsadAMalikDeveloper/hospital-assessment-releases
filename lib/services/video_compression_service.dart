

// lib/services/video_compression_service.dart

import 'dart:async';
import 'dart:io';
import 'package:light_compressor_v2/light_compressor_v2.dart';
import 'package:path_provider/path_provider.dart';

class VideoCompressionResult {
  final File file;
  final int originalSizeBytes;
  final int compressedSizeBytes;

  VideoCompressionResult({
    required this.file,
    required this.originalSizeBytes,
    required this.compressedSizeBytes,
  });

  String get originalSizeMB =>
      (originalSizeBytes / 1024 / 1024).toStringAsFixed(1);

  String get compressedSizeMB =>
      (compressedSizeBytes / 1024 / 1024).toStringAsFixed(1);

  double get ratio => originalSizeBytes / compressedSizeBytes;
}

class VideoCompressionService {
  // Per-instance (not singleton) — each VideoQuestionWidget gets its own
  // LightCompressor so concurrent compressions never interfere.
  final LightCompressor _compressor = LightCompressor();

  static const int targetSizeMB = 5;
  int get _maxBytes => targetSizeMB * 1024 * 1024;

  // ── Single persistent subscription ────────────────────────────────────────
  // ONE StreamSubscription for the lifetime of a compression job.
  // We cancel it before re-subscribing so there is never more than one
  // active listener at a time — this is what caused the shaking bar.
  StreamSubscription<double>? _progressSub;

  // Current pass offsets — updated before each pass so the single listener
  // maps raw 0–100 into the correct slice of overall 0.0–1.0 progress.
  double _passBase = 0.0;
  double _passSpan = 0.33;

  // The widget's callback, stored so the single listener can reach it.
  Function(double)? _onProgress;

  // ── Public progress stream (optional StreamBuilder usage) ─────────────────
  Stream<double> get progressStream =>
      _compressor.onProgressUpdated.map((p) => p / 100.0);

  // ── Copy to permanent storage ──────────────────────────────────────────────
  Future<File> copyToPermanentStorage(
      File tempFile, String aid, String qid) async {
    final appDir = await getApplicationDocumentsDirectory();
    final videoDir = Directory('${appDir.path}/assessment_videos');
    if (!await videoDir.exists()) {
      await videoDir.create(recursive: true);
    }
    return tempFile.copy('${videoDir.path}/video_${aid}_${qid}.mp4');
  }

  // ── Main compression entry point ──────────────────────────────────────────
  Future<VideoCompressionResult?> compressVideo(
      String sourcePath, {
        Function(double progress)? onProgress,
      }) async {
    final sourceFile = File(sourcePath);
    final originalSize = await sourceFile.length();

    // Skip compression if already small enough.
    if (originalSize <= _maxBytes) {
      onProgress?.call(1.0);
      return VideoCompressionResult(
        file: sourceFile,
        originalSizeBytes: originalSize,
        compressedSizeBytes: originalSize,
      );
    }

    _onProgress = onProgress;

    // Cancel any leftover subscription from a previous job, then
    // create exactly ONE new subscription for this entire job.
    // All three passes share it — _passBase/_passSpan shift between passes.
    _progressSub?.cancel();
    _progressSub = _compressor.onProgressUpdated.listen((rawPercent) {
      final overall = _passBase + (rawPercent / 100.0) * _passSpan;
      _onProgress?.call(overall.clamp(0.0, 1.0));
    });

    try {
      // Pass 1: 720p @ 2 Mbps  →  overall 0%–33%
      _passBase = 0.0;
      _passSpan = 0.33;
      final result720 =
      await _compress(sourcePath, bitrate: 2, width: 1280, height: 720);
      if (result720 != null && await result720.length() <= _maxBytes) {
        _finish();
        return _buildResult(result720, originalSize);
      }

      // Pass 2: 540p @ 2 Mbps  →  overall 33%–66%
      _passBase = 0.33;
      _passSpan = 0.33;
      final result540 =
      await _compress(sourcePath, bitrate: 2, width: 960, height: 540);
      if (result540 != null && await result540.length() <= _maxBytes) {
        _finish();
        return _buildResult(result540, originalSize);
      }

      // Pass 3: 480p @ 1 Mbps  →  overall 66%–100%
      _passBase = 0.66;
      _passSpan = 0.34;
      final result480 =
      await _compress(sourcePath, bitrate: 1, width: 854, height: 480);
      if (result480 != null) {
        _finish();
        return _buildResult(result480, originalSize);
      }

      _finish();
      return null;
    } catch (e) {
      _finish();
      rethrow;
    }
  }

  // ── Tear down subscription and snap to 100% ───────────────────────────────
  void _finish() {
    _progressSub?.cancel();
    _progressSub = null;
    _onProgress?.call(1.0);
    _onProgress = null;
  }

  // ── Single-pass internal compress ─────────────────────────────────────────
  Future<File?> _compress(
      String path, {
        required int bitrate,
        required int width,
        required int height,
      }) async {
    final videoName =
        'assessment_${DateTime.now().millisecondsSinceEpoch}.mp4';

    final Result response = await _compressor.compressVideo(
      path: path,
      videoQuality: VideoQuality.medium,
      isMinBitrateCheckEnabled: false,
      disableAudio: false,
      video: Video(
        videoName: videoName,
        videoBitrateInMbps: bitrate,
        videoWidth: width,
        videoHeight: height,
      ),
      android: AndroidConfig(
        isSharedStorage: false,
        saveAt: SaveAt.Movies,
      ),
      ios: IOSConfig(
        saveInGallery: false,
      ),
    );

    if (response is OnSuccess) {
      final file = File(response.destinationPath);
      if (await file.exists()) return file;
    }
    return null;
  }

  Future<VideoCompressionResult> _buildResult(
      File file, int originalSize) async {
    final compressedSize = await file.length();
    return VideoCompressionResult(
      file: file,
      originalSizeBytes: originalSize,
      compressedSizeBytes: compressedSize,
    );
  }

  // ── Cancel ────────────────────────────────────────────────────────────────
  // Only cancels THIS instance — other question cards are unaffected.
  Future<void> cancelCompression() async {
    _finish();
    await _compressor.cancelCompression();
  }
}

// // lib/services/video_compression_service.dart
//
// import 'dart:io';
// import 'package:light_compressor_v2/light_compressor_v2.dart';
// import 'package:path_provider/path_provider.dart';
//
// class VideoCompressionResult {
//   final File file;
//   final int originalSizeBytes;
//   final int compressedSizeBytes;
//
//   VideoCompressionResult({
//     required this.file,
//     required this.originalSizeBytes,
//     required this.compressedSizeBytes,
//   });
//
//   String get originalSizeMB =>
//       (originalSizeBytes / 1024 / 1024).toStringAsFixed(1);
//
//   String get compressedSizeMB =>
//       (compressedSizeBytes / 1024 / 1024).toStringAsFixed(1);
//
//   double get ratio => originalSizeBytes / compressedSizeBytes;
// }
//
// class VideoCompressionService {
//   static final VideoCompressionService _instance =
//   VideoCompressionService._internal();
//
//   factory VideoCompressionService() => _instance;
//
//   VideoCompressionService._internal();
//
//   final LightCompressor _compressor = LightCompressor();
//
//   /// Target max file size
//   static const int targetSizeMB = 5;
//
//   /// Copy compressed file to permanent storage
//   Future<File> copyToPermanentStorage(
//       File tempFile, String aid, String qid) async {
//     final appDir = await getApplicationDocumentsDirectory();
//
//     final videoDir = Directory('${appDir.path}/assessment_videos');
//
//     if (!await videoDir.exists()) {
//       await videoDir.create(recursive: true);
//     }
//
//     final permanentPath =
//         '${videoDir.path}/video_${aid}_${qid}.mp4';
//
//     return tempFile.copy(permanentPath);
//   }
//
//   /// MAIN COMPRESSION
//   Future<VideoCompressionResult?> compressVideo(
//       String sourcePath, {
//         Function(double progress)? onProgress,
//       }) async {
//     final sourceFile = File(sourcePath);
//     final originalSize = await sourceFile.length();
//
//     // ✅ skip compression if file <= 10MB
//     if (originalSize <= 5 * 1024 * 1024) {
//       return VideoCompressionResult(
//         file: sourceFile,
//         originalSizeBytes: originalSize,
//         compressedSizeBytes: originalSize,
//       );
//     }
//     // _compressor.onProgressUpdated.listen((p) {
//     //   onProgress?.call(p / 100);
//     // });
//     _compressor.onProgressUpdated.listen((p) {
//       onProgress?.call((p / 100) * 0.33);
//     });
//     /// PASS 1 : 720p
//     final result720 = await _compress(
//       sourcePath,
//       bitrate: 2,
//       width: 1280,
//       height: 720,
//     );
//
//     if (result720 != null && await result720.length() <= _maxBytes) {
//       return _buildResult(result720, originalSize);
//     }
//
//     _compressor.onProgressUpdated.listen((p) {
//       onProgress?.call(0.33 + (p / 100) * 0.33);
//     });
//     /// PASS 2 : 540p
//     final result540 = await _compress(
//       sourcePath,
//       bitrate: 2,
//       width: 960,
//       height: 540,
//     );
//
//     if (result540 != null && await result540.length() <= _maxBytes) {
//       return _buildResult(result540, originalSize);
//     }
//
//     _compressor.onProgressUpdated.listen((p) {
//       onProgress?.call(0.66 + (p / 100) * 0.34);
//     });
//     /// PASS 3 : 480p
//     final result480 = await _compress(
//       sourcePath,
//       bitrate: 1,
//       width: 854,
//       height: 480,
//     );
//
//     if (result480 != null) {
//       return _buildResult(result480, originalSize);
//     }
//
//     return null;
//   }
//
//   int get _maxBytes => targetSizeMB * 1024 * 1024;
//
//   Future<File?> _compress(
//       String path, {
//         required int bitrate,
//         required int width,
//         required int height,
//       }) async {
//     final videoName =
//         'assessment_${DateTime.now().millisecondsSinceEpoch}.mp4';
//
//     final Result response = await _compressor.compressVideo(
//       path: path,
//       videoQuality: VideoQuality.medium,
//       isMinBitrateCheckEnabled: false,
//       disableAudio: false,
//       video: Video(
//         videoName: videoName,
//         videoBitrateInMbps: bitrate,
//         videoWidth: width,
//         videoHeight: height,
//       ),
//       android: AndroidConfig(
//         isSharedStorage: false,
//         saveAt: SaveAt.Movies,
//       ),
//       ios: IOSConfig(
//         saveInGallery: false,
//       ),
//     );
//
//     if (response is OnSuccess) {
//       final file = File(response.destinationPath);
//       if (await file.exists()) {
//         return file;
//       }
//     }
//
//     return null;
//   }
//
//   Future<VideoCompressionResult> _buildResult(
//       File file, int originalSize) async {
//     final compressedSize = await file.length();
//
//     return VideoCompressionResult(
//       file: file,
//       originalSizeBytes: originalSize,
//       compressedSizeBytes: compressedSize,
//     );
//   }
//
//   Future<void> cancelCompression() async {
//     await _compressor.cancelCompression();
//   }
//
//   Stream<double> get progressStream =>
//       _compressor.onProgressUpdated.map((p) => p / 100);
// }
//
//
//
// // // lib/services/video_compression_service.dart
// //
// // import 'dart:io';
// // import 'package:light_compressor_v2/light_compressor_v2.dart';
// // import 'package:path_provider/path_provider.dart';
// //
// // class VideoCompressionResult {
// //   final File file;
// //   final int originalSizeBytes;
// //   final int compressedSizeBytes;
// //
// //   VideoCompressionResult({
// //     required this.file,
// //     required this.originalSizeBytes,
// //     required this.compressedSizeBytes,
// //   });
// //
// //   String get originalSizeMB =>
// //       (originalSizeBytes / 1024 / 1024).toStringAsFixed(1);
// //   String get compressedSizeMB =>
// //       (compressedSizeBytes / 1024 / 1024).toStringAsFixed(1);
// //   double get ratio => originalSizeBytes / compressedSizeBytes;
// // }
// //
// // class VideoCompressionService {
// //   static final VideoCompressionService _instance =
// //   VideoCompressionService._internal();
// //   factory VideoCompressionService() => _instance;
// //   VideoCompressionService._internal();
// //
// //   final LightCompressor _lightCompressor = LightCompressor();
// // // lib/services/video_compression_service.dart
// // // Add this helper method:
// //
// //   Future<File> copyToPermanentStorage(File tempFile, String aid, String qid) async {
// //     final appDir = await getApplicationDocumentsDirectory();
// //
// //     // Create a dedicated folder for assessment videos
// //     final videoDir = Directory('${appDir.path}/assessment_videos');
// //     if (!await videoDir.exists()) {
// //       await videoDir.create(recursive: true);
// //     }
// //
// //     // Permanent filename — aid+qid makes it unique and findable
// //     final permanentPath = '${videoDir.path}/video_${aid}_${qid}.mp4';
// //     final permanentFile = await tempFile.copy(permanentPath);
// //     return permanentFile;
// //   }
// //   Future<VideoCompressionResult?> compressVideo(
// //       String sourcePath, {
// //         Function(double progress)? onProgress,
// //       }) async {
// //     final sourceFile = File(sourcePath);
// //     final originalSize = await sourceFile.length();
// //
// //     final videoName =
// //         'assessment_${DateTime.now().millisecondsSinceEpoch}.mp4';
// //
// //     // Progress via stream — subscribe BEFORE calling compressVideo
// //     _lightCompressor.onProgressUpdated.listen((progress) {
// //       onProgress?.call(progress / 100.0);
// //     });
// //
// //     final Result response = await _lightCompressor.compressVideo(
// //       path: sourcePath,
// //
// //       // ── VideoQuality ──────────────────────────────────────────────────────
// //       // We pass 'medium' here but it's OVERRIDDEN by videoBitrateInMbps
// //       // inside Video(). The quality preset only matters when
// //       // videoBitrateInMbps is null.
// //       videoQuality: VideoQuality.medium,
// //
// //       // ── isMinBitrateCheckEnabled ──────────────────────────────────────────
// //       // MUST be false — the min threshold is 2 Mbps, and if the source
// //       // is already below that (e.g. a previously compressed clip), it
// //       // skips compression entirely and returns the original.
// //       // Since we're forcing 3 Mbps custom bitrate, set false to always run.
// //       isMinBitrateCheckEnabled: false,
// //
// //       // ── Video class ───────────────────────────────────────────────────────
// //       video: Video(
// //         videoName: videoName,
// //
// //         // ── Custom bitrate — THE KEY SETTING ─────────────────────────────
// //         // 3 Mbps × 30 sec = 90 Mb = 11.25 MB video
// //         // + ~0.5 MB audio (128kbps × 30s)
// //         // = ~11.75 MB total — well under 15 MB ✅
// //         //
// //         // This completely overrides the VideoQuality percentage calculation.
// //         // S24 Ultra 4K source @ ~50 Mbps → forced down to 3 Mbps.
// //         videoBitrateInMbps: 3,
// //       ),
// //
// //       // ── Android config ────────────────────────────────────────────────────
// //       // isSharedStorage: false → saves to app-specific cache directory.
// //       // No WRITE_EXTERNAL_STORAGE permission needed on Android 10+.
// //       // The output path is returned in OnSuccess.destinationPath.
// //       android: AndroidConfig(
// //         isSharedStorage: false,
// //         saveAt: SaveAt.Movies,
// //       ),
// //
// //       // ── iOS config ────────────────────────────────────────────────────────
// //       // saveInGallery: false → don't pollute the user's photo library
// //       // with compressed assessment copies.
// //       ios: IOSConfig(
// //         saveInGallery: false,
// //       ),
// //
// //       disableAudio: false,
// //     );
// //
// //     // ── Handle result ─────────────────────────────────────────────────────
// //     if (response is OnSuccess) {
// //       final outputFile = File(response.destinationPath);
// //       if (!await outputFile.exists()) return null;
// //
// //       final compressedSize = await outputFile.length();
// //
// //       // Safety check — shouldn't happen with 3 Mbps but guard anyway
// //       if (compressedSize > 15 * 1024 * 1024) {
// //         return _fallbackCompress(sourcePath, originalSize);
// //       }
// //
// //       return VideoCompressionResult(
// //         file: outputFile,
// //         originalSizeBytes: originalSize,
// //         compressedSizeBytes: compressedSize,
// //       );
// //     } else if (response is OnFailure) {
// //       throw Exception(response.message);
// //     } else if (response is OnCancelled) {
// //       return null;
// //     }
// //
// //     return null;
// //   }
// //
// //   /// Fallback: 2 Mbps if 3 Mbps pass still exceeds 15 MB.
// //   /// Only triggers on extreme high-motion scenes (unlikely in hospital rooms).
// //   Future<VideoCompressionResult?> _fallbackCompress(
// //       String sourcePath, int originalSize) async {
// //     final videoName = 'assessment_fallback_${DateTime.now().millisecondsSinceEpoch}.mp4';
// //
// //     final Result response = await _lightCompressor.compressVideo(
// //       path: sourcePath,
// //       videoQuality: VideoQuality.very_low,
// //       isMinBitrateCheckEnabled: false,
// //       video: Video(
// //         videoName: videoName,
// //         videoBitrateInMbps: 2, // 2 Mbps × 30s = ~7.5 MB ✅
// //       ),
// //       android: AndroidConfig(
// //         isSharedStorage: false,
// //         saveAt: SaveAt.Movies,
// //       ),
// //       ios: IOSConfig(saveInGallery: false),
// //       disableAudio: false,
// //     );
// //
// //     if (response is OnSuccess) {
// //       final outputFile = File(response.destinationPath);
// //       final compressedSize = await outputFile.length();
// //       return VideoCompressionResult(
// //         file: outputFile,
// //         originalSizeBytes: originalSize,
// //         compressedSizeBytes: compressedSize,
// //       );
// //     }
// //     return null;
// //   }
// //
// //   Future<void> cancelCompression() async {
// //     await _lightCompressor.cancelCompression();
// //   }
// //
// //   /// Progress stream — use this in StreamBuilder if you prefer
// //   Stream<double> get progressStream =>
// //       _lightCompressor.onProgressUpdated.map((p) => p / 100.0);
// // }