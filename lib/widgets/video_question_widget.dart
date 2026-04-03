// lib/widgets/video_question_widget.dart

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:chewie/chewie.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import '../services/video_compression_service.dart';
import '../providers/assessment_provider.dart';
import '../models/api_response_model.dart';
import '../Utils/ToastMessages.dart';

class VideoQuestionWidget extends StatefulWidget {
  final String qid;
  final String aid;
  final String sid;
  final String questionDescription;
  final AssessmentProvider provider;
  final bool isOffline;

  const VideoQuestionWidget({
    Key? key,
    required this.qid,
    required this.aid,
    required this.sid,
    required this.questionDescription,
    required this.provider,
    this.isOffline = false,
  }) : super(key: key);

  @override
  State<VideoQuestionWidget> createState() => _VideoQuestionWidgetState();
}

class _VideoQuestionWidgetState extends State<VideoQuestionWidget>
    with SingleTickerProviderStateMixin,AutomaticKeepAliveClientMixin {
  // Per-instance service — each widget gets its own LightCompressor.
  final _compressionService = VideoCompressionService();
  final Toast _toast = Toast();

  // ── State ──────────────────────────────────────────────────────────────────
  File? _selectedVideo;
  File? _compressedVideo;
  double _compressionProgress = 0;
  bool _isCompressing = false;
  bool _isUploading = false;
  VideoCompressionResult? _compressionResult;

  // ── Preview controllers (local compressed video only) ─────────────────────
  VideoPlayerController? _previewController;
  ChewieController? _previewChewieController;

  // ── Pulse animation ────────────────────────────────────────────────────────
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // NOTE: _progressSub is REMOVED from the widget.
  // Progress is now delivered via the onProgress callback passed directly
  // into compressVideo(). The service manages its own single subscription
  // internally. No widget-side subscription = no duplicate listeners.
  @override
  bool get wantKeepAlive => true;
  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _disposePreviewControllers();
    super.dispose();
  }

  void _disposePreviewControllers() {
    _previewChewieController?.dispose();
    _previewChewieController = null;
    _previewController?.dispose();
    _previewController = null;
  }

  // ── Uploaded video helpers ─────────────────────────────────────────────────

  bool get _hasUploaded {
    final list = widget.provider.videoList;
    if (list == null || list.isEmpty) return false;
    return list.any((v) => v.qid == widget.qid);
  }

  String? get _uploadedPath {
    final list = widget.provider.videoList;
    if (list == null || list.isEmpty) return null;
    try {
      return list.firstWhere((v) => v.qid == widget.qid).doc_id;
    } catch (_) {
      return null;
    }
  }

  // ── Picker ─────────────────────────────────────────────────────────────────

  void _showPickerSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Wrap(children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 14, 20, 4),
            child: Text('Select Video',
                style:
                TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.videocam, color: Colors.blue),
            ),
            title: const Text('Record Video',
                style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Max 30 seconds'),
            onTap: () {
              Navigator.pop(context);
              _pickVideo(ImageSource.camera);
            },
          ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(10)),
              child:
              const Icon(Icons.video_library, color: Colors.purple),
            ),
            title: const Text('Choose from Gallery',
                style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Trim & crop before uploading'),
            onTap: () {
              Navigator.pop(context);
              _pickVideoFromGallery();
            },
          ),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  Future<void> _pickVideo(ImageSource source) async {
    final picked = await ImagePicker().pickVideo(
      source: source,
      maxDuration: const Duration(seconds: 30),
    );
    if (picked == null || !mounted) return;

    _disposePreviewControllers();
    setState(() {
      _selectedVideo = File(picked.path);
      _compressedVideo = null;
      _compressionResult = null;
      _compressionProgress = 0;
    });

    await _compressVideo(picked.path);
  }

  Future<void> _pickVideoFromGallery() async {
    final picked =
    await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (picked == null || !mounted) return;

    String pathToProcess = picked.path;

    final tempVc = VideoPlayerController.file(File(picked.path));
    try {
      await tempVc.initialize();
      final duration = tempVc.value.duration;
      await tempVc.dispose();
      if (!mounted) return;

      const maxMs = 30 * 1000;
      if (duration.inMilliseconds > maxMs + 200) {
        final result = await VideoTrimmerScreen.show(
          context,
          picked.path,
          maxSeconds: 30,
        );
        if (result == null || !mounted) return;
        pathToProcess = result;
      }
    } catch (_) {
      await tempVc.dispose();
      if (!mounted) return;
    }

    _disposePreviewControllers();
    setState(() {
      _selectedVideo = File(pathToProcess);
      _compressedVideo = null;
      _compressionResult = null;
      _compressionProgress = 0;
    });

    await _compressVideo(pathToProcess);
  }

  // ── Compression ────────────────────────────────────────────────────────────

  Future<void> _compressVideo(String sourcePath) async {
    setState(() {
      _isCompressing = true;
      _compressionProgress = 0;
    });

    try {
      final result = await _compressionService.compressVideo(
        sourcePath,
        // Progress arrives via callback — the service calls this from its
        // single internal listener. No widget-side stream subscription needed.
        onProgress: (p) {
          if (mounted) setState(() => _compressionProgress = p);
        },
      );

      if (!mounted) return;

      if (result != null) {
        setState(() => _isCompressing = false);
        await _handleCompressedVideo(result);
      } else {
        // Cancelled
        setState(() {
          _isCompressing = false;
          _selectedVideo = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCompressing = false;
          _selectedVideo = null;
        });
        _toast.showErrorToast('Compression failed: $e');
      }
    }
  }

  Future<void> _cancelCompression() async {
    await _compressionService.cancelCompression();
    if (mounted) {
      setState(() {
        _isCompressing = false;
        _selectedVideo = null;
        _compressionProgress = 0;
      });
    }
  }

  // ── Route after compression ────────────────────────────────────────────────

  Future<void> _handleCompressedVideo(VideoCompressionResult result) async {
    if (widget.isOffline) {
      File permanentFile;
      try {
        permanentFile = await _compressionService.copyToPermanentStorage(
          result.file,
          widget.aid,
          widget.qid,
        );
      } catch (e) {
        _toast.showErrorToast('Failed to save video: $e');
        return;
      }

      final APIResponse? res = await widget.provider.pickVideoOffline(
        context,
        widget.aid,
        widget.qid,
        permanentFile.path,
      );
      if (!mounted) return;
      if (res?.status?.toLowerCase() == 'success') {
        _toast.showSuccessToast('Video saved locally');
        await widget.provider.getVideosListOffline(context, widget.aid);
        setState(() {
          _selectedVideo = null;
          _compressedVideo = null;
          _compressionResult = null;
        });
      } else {
        _toast.showErrorToast(res?.message ?? 'Failed to save video');
      }
    } else {
      setState(() {
        _compressionResult = result;
        _compressedVideo = result.file;
      });
      _initPreviewControllers(result.file.path);
    }
  }

  // ── Local preview ──────────────────────────────────────────────────────────

  void _initPreviewControllers(String path) {
    _disposePreviewControllers();
    _previewController = VideoPlayerController.file(File(path));
    _previewController!.initialize().then((_) {
      if (!mounted) return;
      _previewChewieController = ChewieController(
        videoPlayerController: _previewController!,
        autoPlay: false,
        looping: false,
        aspectRatio: _previewController!.value.aspectRatio,
        materialProgressColors: ChewieProgressColors(
          playedColor: Colors.blue,
          handleColor: Colors.blueAccent,
          bufferedColor: Colors.blue.shade100,
          backgroundColor: Colors.grey.shade300,
        ),
      );
      if (mounted) setState(() {});
    });
  }

  // ── Upload ─────────────────────────────────────────────────────────────────

  Future<void> _uploadVideo() async {
    if (_compressedVideo == null) return;
    setState(() => _isUploading = true);

    final filename =
        'video_${widget.qid}_${DateTime.now().millisecondsSinceEpoch}.mp4';

    final APIResponse? res = await widget.provider.uploadVideo(
      context,
      widget.aid,
      widget.qid,
      widget.sid,
      filename,
      _compressedVideo!,
    );

    if (!mounted) return;
    setState(() => _isUploading = false);

    if (res?.status?.toLowerCase() == 'success') {
      _toast.showSuccessToast(res!.message ?? 'Video uploaded successfully');
      _disposePreviewControllers();
      setState(() {
        _selectedVideo = null;
        _compressedVideo = null;
        _compressionResult = null;
      });
      await widget.provider.getVideosList(context, widget.aid);
    } else {
      _toast.showErrorToast(res?.message ?? 'Upload failed');
    }
  }

  // ── Play uploaded video ────────────────────────────────────────────────────

  Future<void> _openUploadedVideo() async {
    final path = _uploadedPath;
    if (path == null) return;

    if (widget.isOffline) {
      await showDialog(
        context: context,
        builder: (ctx) => _VideoPlayerDialog(filePath: path),
      );
    } else {
      final url =
          'https://apps.slichealth.com/ords/ihmis_admin/assesment/video?doc_id=$path';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url),
            mode: LaunchMode.externalApplication);
      } else {
        _toast.showErrorToast('Could not open video');
      }
    }
  }

  // ── Delete ─────────────────────────────────────────────────────────────────

  Future<void> _deleteUploadedVideo() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Video'),
        content:
        const Text('Are you sure you want to delete this video?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style:
              TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    if (widget.isOffline) {
      final res = await widget.provider
          .deleteVideoOffline(context, widget.aid, widget.qid);
      if (!mounted) return;
      if (res.status?.toLowerCase() == 'success') {
        _toast.showSuccessToast('Video deleted');
        await widget.provider.getVideosListOffline(context, widget.aid);
      } else {
        _toast.showErrorToast(res.message ?? 'Delete failed');
      }
    } else {
      final res = await widget.provider
          .deleteVideo(context, widget.aid, widget.qid);
      if (!mounted) return;
      if (res.status?.toLowerCase() == 'success') {
        _toast.showSuccessToast('Video deleted');
        await widget.provider.getVideosList(context, widget.aid);
      } else {
        _toast.showErrorToast(res.message ?? 'Delete failed');
      }
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SafeArea(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        elevation: 2,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.videocam_outlined,
                    size: 18, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.questionDescription,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ]),
              const SizedBox(height: 14),

              if (_hasUploaded && _selectedVideo == null)
                _buildUploadedBadge(),
              if (_isCompressing) _buildCompressionProgress(),
              if (!_isCompressing && _compressedVideo != null) ...[
                _buildCompressionStats(),
                const SizedBox(height: 10),
                if (_previewChewieController != null) _buildLocalPreview(),
                const SizedBox(height: 12),
                if (_isUploading)
                  _buildUploadProgress()
                else
                  _buildPostCompressionActions(),
              ],
              if (_selectedVideo == null &&
                  !_isCompressing &&
                  !_hasUploaded)
                _buildPickButton(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Sub-widgets ────────────────────────────────────────────────────────────

  Widget _buildPickButton() => Center(
    child: OutlinedButton.icon(
      onPressed: _showPickerSheet,
      icon: const Icon(Icons.video_call),
      label: const Text('Upload Video'),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.blue,
        side: const BorderSide(color: Colors.blue),
        padding:
        const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
      ),
    ),
  );

  Widget _buildCompressionProgress() => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.orange.shade50,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.orange.shade200),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Icon(Icons.compress, size: 16, color: Colors.orange),
          const SizedBox(width: 8),
          Text('Compressing video...',
              style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.orange.shade800,
                  fontWeight: FontWeight.w600)),
          const Spacer(),
          Text(
            '${(_compressionProgress * 100).toStringAsFixed(0)}%',
            style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.orange.shade800,
                fontWeight: FontWeight.bold),
          ),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: _compressionProgress,
            backgroundColor: Colors.orange.shade100,
            valueColor:
            const AlwaysStoppedAnimation(Colors.orange),
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Optimizing for upload — do not close the app',
                style: TextStyle(
                    fontSize: 10, color: Colors.grey.shade600)),
            TextButton.icon(
              onPressed: _cancelCompression,
              icon: const Icon(Icons.close, size: 12),
              label: const Text('Cancel',
                  style: TextStyle(fontSize: 11)),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _buildCompressionStats() {
    if (_compressionResult == null) return const SizedBox();
    final savedMB = ((_compressionResult!.originalSizeBytes -
        _compressionResult!.compressedSizeBytes) /
        1024 /
        1024)
        .toStringAsFixed(1);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _stat('Before', '${_compressionResult!.originalSizeMB} MB',
              Icons.file_present, Colors.grey.shade600),
          Icon(Icons.arrow_forward,
              size: 14, color: Colors.grey.shade400),
          _stat('After', '${_compressionResult!.compressedSizeMB} MB',
              Icons.compress, Colors.green.shade700),
          _stat('Saved', '$savedMB MB', Icons.savings,
              Colors.blue.shade700),
          _stat(
              'Ratio',
              '${_compressionResult!.ratio.toStringAsFixed(1)}×',
              Icons.speed,
              Colors.purple.shade700),
        ],
      ),
    );
  }

  Widget _stat(
      String label, String value, IconData icon, Color color) =>
      Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(height: 2),
        Text(label,
            style:
            TextStyle(fontSize: 9, color: Colors.grey.shade500)),
        Text(value,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color)),
      ]);

  Widget _buildLocalPreview() => ClipRRect(
    borderRadius: BorderRadius.circular(10),
    child: AspectRatio(
      aspectRatio: _previewController!.value.aspectRatio,
      child: Chewie(controller: _previewChewieController!),
    ),
  );

  Widget _buildPostCompressionActions() => Row(children: [
    OutlinedButton.icon(
      onPressed: _showPickerSheet,
      icon: const Icon(Icons.refresh, size: 16),
      label: const Text('Re-pick'),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.grey.shade700,
        side: BorderSide(color: Colors.grey.shade400),
        padding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
      ),
    ),
    const SizedBox(width: 10),
    Expanded(
      child: ElevatedButton.icon(
        onPressed: _uploadVideo,
        icon: const Icon(Icons.cloud_upload),
        label: const Text('Upload Video'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          elevation: 2,
        ),
      ),
    ),
  ]);

  Widget _buildUploadProgress() {
    final progress = widget.provider.uploadVideoProgress;
    final totalBytes = _compressedVideo?.lengthSync() ?? 0;
    final uploadedMB =
    (totalBytes / 1024 / 1024 * progress).toStringAsFixed(1);
    final totalMB = (totalBytes / 1024 / 1024).toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.blue.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.cloud_upload,
                    color: Colors.white, size: 16),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Uploading to server...',
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade800)),
                  Text('Please keep the app open',
                      style: TextStyle(
                          fontSize: 10, color: Colors.blue.shade600)),
                ],
              ),
            ),
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.blue.shade100,
              valueColor:
              AlwaysStoppedAnimation(Colors.blue.shade600),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$uploadedMB MB / $totalMB MB',
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w500)),
              if (progress < 1.0)
                Row(children: [
                  SizedBox(
                    width: 10,
                    height: 10,
                    child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: Colors.blue.shade600),
                  ),
                  const SizedBox(width: 4),
                  Text('Sending...',
                      style: TextStyle(
                          fontSize: 10,
                          color: Colors.blue.shade600)),
                ])
              else
                Row(children: [
                  const Icon(Icons.check_circle,
                      size: 14, color: Colors.green),
                  const SizedBox(width: 4),
                  Text('Done',
                      style: TextStyle(
                          fontSize: 10,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w600)),
                ]),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUploadedBadge() => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(children: [
      Expanded(
        child: InkWell(
          onTap: _openUploadedVideo,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.green.shade300),
            ),
            child: Row(children: [
              const Icon(Icons.check_circle,
                  color: Colors.green, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.isOffline
                          ? 'Video saved locally'
                          : 'Video uploaded',
                      style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w700,
                          fontSize: 13),
                    ),
                    Text('Tap to play',
                        style: TextStyle(
                            fontSize: 10,
                            color: Colors.green.shade600)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.play_arrow,
                        color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text('PLAY',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ]),
          ),
        ),
      ),
      const SizedBox(width: 8),
      _iconAction(
        icon: Icons.swap_horiz,
        color: Colors.orange,
        tooltip: 'Replace',
        onTap: _showPickerSheet,
      ),
      const SizedBox(width: 6),
      widget.provider.isLoadingVideoDelete == true
          ? const SizedBox(
        width: 36,
        height: 36,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      )
          : _iconAction(
        icon: Icons.delete_outline,
        color: Colors.red,
        tooltip: 'Delete',
        onTap: _deleteUploadedVideo,
      ),
    ]),
  );

  Widget _iconAction({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) =>
      Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: color.withOpacity(0.4)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
        ),
      );
}

// ══════════════════════════════════════════════════════════════════════════════
// Isolated video player dialog — unchanged
// ══════════════════════════════════════════════════════════════════════════════

class _VideoPlayerDialog extends StatefulWidget {
  final String filePath;
  const _VideoPlayerDialog({required this.filePath});

  @override
  State<_VideoPlayerDialog> createState() => _VideoPlayerDialogState();
}

class _VideoPlayerDialogState extends State<_VideoPlayerDialog> {
  VideoPlayerController? _controller;
  ChewieController? _chewieController;
  bool _initialized = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      final file = File(widget.filePath);
      if (!await file.exists()) {
        if (mounted) {
          setState(() =>
          _error = 'Video file not found.\nPath: ${widget.filePath}');
        }
        return;
      }
      _controller = VideoPlayerController.file(file);
      await _controller!.initialize();
      if (!mounted) return;
      _chewieController = ChewieController(
        videoPlayerController: _controller!,
        autoPlay: true,
        looping: false,
        aspectRatio: _controller!.value.aspectRatio,
        materialProgressColors: ChewieProgressColors(
          playedColor: Colors.blue,
          handleColor: Colors.blueAccent,
          bufferedColor: Colors.blue.shade100,
          backgroundColor: Colors.grey.shade800,
        ),
      );
      setState(() => _initialized = true);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: const EdgeInsets.all(16),
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(children: [
              const Icon(Icons.videocam, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Video Preview',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ]),
          ),
          const Divider(color: Colors.white24, height: 1),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(children: [
                const Icon(Icons.error_outline,
                    color: Colors.red, size: 40),
                const SizedBox(height: 8),
                const Text('Could not play video',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(_error!,
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 11),
                    textAlign: TextAlign.center),
              ]),
            )
          else if (!_initialized)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Column(children: [
                CircularProgressIndicator(color: Colors.blue),
                SizedBox(height: 12),
                Text('Loading video...',
                    style:
                    TextStyle(color: Colors.white54, fontSize: 12)),
              ]),
            )
          else
            ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              child: AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: Chewie(controller: _chewieController!),
              ),
            ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// VideoTrimmerScreen and all supporting widgets — unchanged
// ══════════════════════════════════════════════════════════════════════════════

class VideoTrimmerScreen extends StatefulWidget {
  final String videoPath;
  final int maxDurationSeconds;

  const VideoTrimmerScreen({
    Key? key,
    required this.videoPath,
    this.maxDurationSeconds = 30,
  }) : super(key: key);

  static Future<String?> show(BuildContext context, String videoPath,
      {int maxSeconds = 30}) {
    return Navigator.push<String>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => VideoTrimmerScreen(
          videoPath: videoPath,
          maxDurationSeconds: maxSeconds,
        ),
      ),
    );
  }

  @override
  State<VideoTrimmerScreen> createState() => _VideoTrimmerScreenState();
}

enum _Step { trim, crop, processing }

class _VideoTrimmerScreenState extends State<VideoTrimmerScreen> {
  VideoPlayerController? _mainController;
  Duration _totalDuration = Duration.zero;
  double _trimStart = 0.0;
  double _trimEnd = 0.0;
  Duration _position = Duration.zero;
  _Step _step = _Step.trim;
  bool _isLoading = true;
  String? _errorMsg;
  String _processingLabel = 'Processing...';
  int _videoWidth = 0;
  int _videoHeight = 0;
  Rect _cropRect = const Rect.fromLTWH(0.05, 0.05, 0.9, 0.9);
  final GlobalKey _previewKey = GlobalKey();
  Size _previewSize = Size.zero;
  VideoPlayerController? _cropPreviewController;

  @override
  void initState() {
    super.initState();
    _loadVideo();
  }

  @override
  void dispose() {
    _mainController?.dispose();
    _cropPreviewController?.dispose();
    super.dispose();
  }

  Future<void> _loadVideo() async {
    try {
      final controller =
      VideoPlayerController.file(File(widget.videoPath));
      await controller.initialize();
      final duration = controller.value.duration;
      final size = controller.value.size;
      controller.addListener(() {
        if (mounted) setState(() => _position = controller.value.position);
      });
      setState(() {
        _mainController = controller;
        _totalDuration = duration;
        _trimStart = 0.0;
        _trimEnd = math.min(
          duration.inMilliseconds.toDouble(),
          widget.maxDurationSeconds * 1000.0,
        );
        _videoWidth = size.width.round();
        _videoHeight = size.height.round();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMsg = e.toString();
        });
      }
    }
  }

  double get _selectedSeconds => (_trimEnd - _trimStart) / 1000.0;
  bool get _trimValid =>
      _selectedSeconds > 0.5 &&
          _selectedSeconds <= widget.maxDurationSeconds;

  String _fmt(double seconds) {
    final s = seconds.round();
    return '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
  }

  void _seekTo(double ms) {
    _mainController?.seekTo(Duration(milliseconds: ms.round()));
  }

  Future<void> _advanceToCrop() async {
    if (!_trimValid) return;
    _mainController?.pause();
    setState(() {
      _step = _Step.processing;
      _processingLabel = 'Preparing crop preview...';
    });
    final dir = await getTemporaryDirectory();
    final trimPath =
        '${dir.path}/trim_prev_${DateTime.now().millisecondsSinceEpoch}.mp4';
    final startSec = _trimStart / 1000.0;
    final durSec = (_trimEnd - _trimStart) / 1000.0;
    final session = await FFmpegKit.execute(
        '-y -i "${widget.videoPath}" -ss $startSec -t $durSec -c copy "$trimPath"');
    final rc = await session.getReturnCode();
    if (!mounted) return;
    if (ReturnCode.isSuccess(rc)) {
      _cropPreviewController?.dispose();
      _cropPreviewController =
          VideoPlayerController.file(File(trimPath));
      await _cropPreviewController!.initialize();
      await _cropPreviewController!.setLooping(true);
      await _cropPreviewController!.play();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final box = _previewKey.currentContext?.findRenderObject()
        as RenderBox?;
        if (box != null && mounted) {
          setState(() => _previewSize = box.size);
        }
      });
      setState(() => _step = _Step.crop);
    } else {
      setState(() {
        _step = _Step.trim;
        _errorMsg = 'Preview generation failed — try a shorter clip';
      });
    }
  }

  Future<void> _applyAndReturn() async {
    setState(() {
      _step = _Step.processing;
      _processingLabel = 'Applying trim & crop...';
    });
    _cropPreviewController?.pause();
    final dir = await getTemporaryDirectory();
    final out =
        '${dir.path}/out_${DateTime.now().millisecondsSinceEpoch}.mp4';
    final startSec = _trimStart / 1000.0;
    final durSec = (_trimEnd - _trimStart) / 1000.0;
    final cmd = '-y -i "${widget.videoPath}" '
        '-ss $startSec -t $durSec '
        '-c copy '
        '"$out"';
    final session = await FFmpegKit.execute(cmd);
    final rc = await session.getReturnCode();
    if (!mounted) return;
    if (ReturnCode.isSuccess(rc)) {
      Navigator.pop(context, out);
    } else {
      setState(() => _step = _Step.crop);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Processing failed — try again'),
            backgroundColor: Colors.red),
      );
    }
  }

  Map<String, int> _cropPixels() {
    final vw = _videoWidth.toDouble();
    final vh = _videoHeight.toDouble();
    final pw = _previewSize.width;
    final ph = _previewSize.height;
    if (pw == 0 || ph == 0) {
      return {'x': 0, 'y': 0, 'w': _videoWidth, 'h': _videoHeight};
    }
    final videoAspect = vw / vh;
    final previewAspect = pw / ph;
    double renderW, renderH, offsetX, offsetY;
    if (videoAspect > previewAspect) {
      renderW = pw;
      renderH = pw / videoAspect;
      offsetX = 0;
      offsetY = (ph - renderH) / 2;
    } else {
      renderH = ph;
      renderW = ph * videoAspect;
      offsetX = (pw - renderW) / 2;
      offsetY = 0;
    }
    final cL = ((_cropRect.left * pw) - offsetX).clamp(0.0, renderW);
    final cT = ((_cropRect.top * ph) - offsetY).clamp(0.0, renderH);
    final cR = ((_cropRect.right * pw) - offsetX).clamp(0.0, renderW);
    final cB = ((_cropRect.bottom * ph) - offsetY).clamp(0.0, renderH);
    final scaleX = vw / renderW;
    final scaleY = vh / renderH;
    final x = (cL * scaleX).round();
    final y = (cT * scaleY).round();
    var w = ((cR - cL) * scaleX).round();
    var h = ((cB - cT) * scaleY).round();
    w = math.max((w ~/ 2) * 2, 2);
    h = math.max((h ~/ 2) * 2, 2);
    return {'x': x, 'y': y, 'w': w, 'h': h};
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: _buildAppBar(),
        body: _isLoading
            ? _buildSpinner('Loading video...')
            : _errorMsg != null
            ? _buildError()
            : _step == _Step.processing
            ? _buildSpinner(_processingLabel)
            : _step == _Step.trim
            ? _buildTrimStep()
            : _buildCropStep(),
      ),
    );
  }

  AppBar _buildAppBar() {
    String title;
    Widget? action;
    VoidCallback? onBack;
    switch (_step) {
      case _Step.trim:
        title = 'Step 1 of 2 — Trim';
        action = TextButton(
          onPressed: _trimValid ? _advanceToCrop : null,
          child: Text('Next →',
              style: TextStyle(
                  color: _trimValid ? Colors.blue : Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                  fontSize: 15)),
        );
        break;
      case _Step.crop:
        title = 'Step 2 of 2 — Crop';
        action = TextButton(
          onPressed: _applyAndReturn,
          child: const Text('Done',
              style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                  fontSize: 15)),
        );
        onBack = () {
          _cropPreviewController?.pause();
          setState(() => _step = _Step.trim);
        };
        break;
      case _Step.processing:
        title = 'Processing...';
        break;
    }
    return AppBar(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      elevation: 0,
      leading: onBack != null
          ? IconButton(
          icon: const Icon(Icons.arrow_back), onPressed: onBack)
          : _step == _Step.trim
          ? IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => Navigator.pop(context, null),
      )
          : null,
      title: Text(title,
          style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w600)),
      actions: [if (action != null) action],
    );
  }

  Widget _buildSpinner(String label) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const CircularProgressIndicator(color: Colors.blue),
      const SizedBox(height: 16),
      Text(label,
          style:
          const TextStyle(color: Colors.white, fontSize: 14)),
    ]),
  );

  Widget _buildError() => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_outline,
            color: Colors.red, size: 48),
        const SizedBox(height: 12),
        Text(_errorMsg ?? 'Unknown error',
            style: const TextStyle(
                color: Colors.white54, fontSize: 12),
            textAlign: TextAlign.center),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () => setState(() {
            _errorMsg = null;
            _step = _Step.trim;
          }),
          child: const Text('Dismiss'),
        ),
      ]),
    ),
  );

  Widget _buildTrimStep() {
    final isOver = _selectedSeconds > widget.maxDurationSeconds;
    final isReady = _totalDuration > Duration.zero;
    return Column(children: [
      Expanded(
        child: GestureDetector(
          onTap: () {
            if (_mainController == null) return;
            if (_mainController!.value.isPlaying) {
              _mainController!.pause();
            } else {
              final pos =
                  _mainController!.value.position.inMilliseconds;
              if (pos < _trimStart || pos >= _trimEnd) {
                _mainController!.seekTo(
                    Duration(milliseconds: _trimStart.round()));
              }
              _mainController!.play();
            }
            setState(() {});
          },
          child: Stack(alignment: Alignment.center, children: [
            _mainController != null &&
                _mainController!.value.isInitialized
                ? Center(
              child: AspectRatio(
                aspectRatio: _mainController!.value.aspectRatio,
                child: VideoPlayer(_mainController!),
              ),
            )
                : const SizedBox(),
            if (_mainController != null &&
                !_mainController!.value.isPlaying)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_arrow,
                    color: Colors.white, size: 40),
              ),
          ]),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: isOver
                  ? Colors.orange.withOpacity(0.15)
                  : Colors.blue.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isOver
                    ? Colors.orange.withOpacity(0.5)
                    : Colors.blue.withOpacity(0.4),
              ),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(
                isOver
                    ? Icons.warning_amber_rounded
                    : Icons.timer_outlined,
                size: 14,
                color: isOver ? Colors.orange : Colors.blue,
              ),
              const SizedBox(width: 6),
              Text(
                isOver
                    ? 'Too long — max ${widget.maxDurationSeconds}s'
                    : isReady
                    ? 'Selected: ${_fmt(_selectedSeconds)}  /  max ${widget.maxDurationSeconds}s'
                    : 'Loading...',
                style: TextStyle(
                  color: isOver ? Colors.orange : Colors.blue,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ]),
          ),
        ),
      ),
      if (isReady)
        _TrimScrubber(
          totalMs: _totalDuration.inMilliseconds.toDouble(),
          startMs: _trimStart,
          endMs: _trimEnd,
          positionMs: _position.inMilliseconds.toDouble(),
          maxDurationMs: widget.maxDurationSeconds * 1000.0,
          onStartChanged: (v) {
            setState(() => _trimStart = v);
            _seekTo(v);
          },
          onEndChanged: (v) {
            setState(() => _trimEnd = v);
            _seekTo(v - 100);
          },
          onSeek: (v) => _seekTo(v),
        ),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Text(
          'Drag the yellow handles to set start and end of your clip',
          style: TextStyle(color: Colors.white38, fontSize: 11),
          textAlign: TextAlign.center,
        ),
      ),
      const SizedBox(height: 8),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
        child: Row(children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context, null),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white30),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _trimValid ? _advanceToCrop : null,
              icon: const Icon(Icons.crop, size: 18),
              label: Text(isOver
                  ? 'Too long'
                  : !isReady
                  ? 'Loading...'
                  : 'Next: Crop ${_fmt(_selectedSeconds)} →'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade800,
                disabledForegroundColor: Colors.white38,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ]),
      ),
    ]);
  }

  Widget _buildCropStep() {
    return Column(children: [
      Expanded(
        child: Stack(children: [
          Positioned.fill(
            child: Container(
              key: _previewKey,
              color: Colors.black,
              child: _cropPreviewController != null &&
                  _cropPreviewController!.value.isInitialized
                  ? Center(
                child: AspectRatio(
                  aspectRatio:
                  _cropPreviewController!.value.aspectRatio,
                  child: VideoPlayer(_cropPreviewController!),
                ),
              )
                  : const Center(
                  child: CircularProgressIndicator(
                      color: Colors.blue)),
            ),
          ),
          Positioned.fill(
            child: _CropOverlay(
              cropRect: _cropRect,
              onCropChanged: (r) {
                if (mounted) setState(() => _cropRect = r);
              },
            ),
          ),
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onDoubleTap: () {
                if (_cropPreviewController == null) return;
                if (_cropPreviewController!.value.isPlaying) {
                  _cropPreviewController!.pause();
                } else {
                  _cropPreviewController!.play();
                }
                setState(() {});
              },
            ),
          ),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Builder(builder: (_) {
              final c = _cropPixels();
              return Text('Output: ${c['w']} × ${c['h']} px',
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500));
            }),
            TextButton.icon(
              onPressed: () => setState(() =>
              _cropRect = const Rect.fromLTWH(0.05, 0.05, 0.9, 0.9)),
              icon: const Icon(Icons.refresh,
                  size: 14, color: Colors.white38),
              label: const Text('Reset',
                  style:
                  TextStyle(color: Colors.white38, fontSize: 12)),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      ),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        child: Text(
          'Drag box to move  •  Drag corners/edges to resize  •  Double-tap to pause',
          style: TextStyle(color: Colors.white38, fontSize: 10),
          textAlign: TextAlign.center,
        ),
      ),
      const SizedBox(height: 12),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
        child: Row(children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context, null),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white30),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _applyAndReturn,
              icon: const Icon(Icons.check_rounded, size: 18),
              label: const Text('Apply & Save'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ]),
      ),
    ]);
  }
}

// ── Trim Scrubber ─────────────────────────────────────────────────────────────

class _TrimScrubber extends StatefulWidget {
  final double totalMs;
  final double startMs;
  final double endMs;
  final double positionMs;
  final double maxDurationMs;
  final ValueChanged<double> onStartChanged;
  final ValueChanged<double> onEndChanged;
  final ValueChanged<double> onSeek;

  const _TrimScrubber({
    required this.totalMs,
    required this.startMs,
    required this.endMs,
    required this.positionMs,
    required this.maxDurationMs,
    required this.onStartChanged,
    required this.onEndChanged,
    required this.onSeek,
  });

  @override
  State<_TrimScrubber> createState() => _TrimScrubberState();
}

class _TrimScrubberState extends State<_TrimScrubber> {
  static const double _trackH = 52.0;
  static const double _handleW = 20.0;
  static const double _minGapMs = 500.0;

  double _msToX(double ms, double trackW) =>
      (ms / widget.totalMs) * trackW;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: LayoutBuilder(builder: (_, box) {
        final trackW = box.maxWidth;
        final startX = _msToX(widget.startMs, trackW);
        final endX = _msToX(widget.endMs, trackW);
        final posX = _msToX(
            widget.positionMs.clamp(widget.startMs, widget.endMs),
            trackW);
        final isOver =
            widget.endMs - widget.startMs > widget.maxDurationMs;
        final accent = isOver ? Colors.orange : Colors.yellow;

        return SizedBox(
          height: _trackH,
          child: Stack(clipBehavior: Clip.none, children: [
            Positioned.fill(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            Positioned(
              left: startX,
              top: 8,
              width: (endX - startX).clamp(0.0, trackW),
              bottom: 8,
              child: GestureDetector(
                onHorizontalDragUpdate: (d) {
                  final delta =
                      d.delta.dx / trackW * widget.totalMs;
                  final dur = widget.endMs - widget.startMs;
                  var newStart = (widget.startMs + delta)
                      .clamp(0.0, widget.totalMs - dur);
                  widget.onStartChanged(newStart);
                  widget.onEndChanged(newStart + dur);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color:
                    accent.withOpacity(isOver ? 0.25 : 0.18),
                    border: Border.all(
                        color: accent.withOpacity(0.6), width: 1),
                  ),
                ),
              ),
            ),
            Positioned(
              left: posX - 1,
              top: 4,
              bottom: 4,
              child: Container(
                width: 2,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
            Positioned(
              left: startX - _handleW / 2,
              top: 0,
              bottom: 0,
              child: GestureDetector(
                onHorizontalDragUpdate: (d) {
                  final dx =
                      d.delta.dx / trackW * widget.totalMs;
                  final newStart = (widget.startMs + dx)
                      .clamp(0.0, widget.endMs - _minGapMs);
                  widget.onStartChanged(newStart);
                },
                child: _Handle(color: accent, isStart: true),
              ),
            ),
            Positioned(
              left: endX - _handleW / 2,
              top: 0,
              bottom: 0,
              child: GestureDetector(
                onHorizontalDragUpdate: (d) {
                  final dx =
                      d.delta.dx / trackW * widget.totalMs;
                  final newEnd = (widget.endMs + dx).clamp(
                      widget.startMs + _minGapMs, widget.totalMs);
                  widget.onEndChanged(newEnd);
                },
                child: _Handle(color: accent, isStart: false),
              ),
            ),
            Positioned(
              left: startX + _handleW / 2 + 4,
              bottom: 0,
              child: Text(_fmtMs(widget.startMs),
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 9,
                      fontWeight: FontWeight.w500)),
            ),
            Positioned(
              right: trackW - endX + _handleW / 2 + 4,
              bottom: 0,
              child: Text(_fmtMs(widget.endMs),
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 9,
                      fontWeight: FontWeight.w500)),
            ),
          ]),
        );
      }),
    );
  }

  String _fmtMs(double ms) {
    final s = (ms / 1000).round();
    return '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
  }
}

class _Handle extends StatelessWidget {
  final Color color;
  final bool isStart;
  const _Handle({required this.color, required this.isStart});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(isStart ? 5 : 0),
          bottomLeft: Radius.circular(isStart ? 5 : 0),
          topRight: Radius.circular(isStart ? 0 : 5),
          bottomRight: Radius.circular(isStart ? 0 : 5),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            3,
                (_) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Container(
                width: 2,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Crop Overlay ──────────────────────────────────────────────────────────────

class _CropOverlay extends StatefulWidget {
  final Rect cropRect;
  final ValueChanged<Rect> onCropChanged;
  const _CropOverlay(
      {required this.cropRect, required this.onCropChanged});

  @override
  State<_CropOverlay> createState() => _CropOverlayState();
}

class _CropOverlayState extends State<_CropOverlay> {
  static const double _h = 28.0;
  static const double _min = 0.08;
  late Rect _rect;

  @override
  void initState() {
    super.initState();
    _rect = widget.cropRect;
  }

  @override
  void didUpdateWidget(_CropOverlay old) {
    super.didUpdateWidget(old);
    if (old.cropRect != widget.cropRect) _rect = widget.cropRect;
  }

  Rect _px(Size s) => Rect.fromLTRB(
    _rect.left * s.width,
    _rect.top * s.height,
    _rect.right * s.width,
    _rect.bottom * s.height,
  );

  void _emit() => widget.onCropChanged(_rect);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, constraints) {
      final size = Size(constraints.maxWidth, constraints.maxHeight);
      final px = _px(size);
      return Stack(children: [
        CustomPaint(size: size, painter: _DimPainter(cropRect: px)),
        Positioned(
          left: px.left + _h / 2,
          top: px.top + _h / 2,
          width: math.max(px.width - _h, 0),
          height: math.max(px.height - _h, 0),
          child: GestureDetector(
            onPanUpdate: (d) {
              final dx = d.delta.dx / size.width;
              final dy = d.delta.dy / size.height;
              setState(() {
                final l = (_rect.left + dx)
                    .clamp(0.0, 1.0 - _rect.width);
                final t = (_rect.top + dy)
                    .clamp(0.0, 1.0 - _rect.height);
                _rect =
                    Rect.fromLTWH(l, t, _rect.width, _rect.height);
              });
              _emit();
            },
            child: Container(color: Colors.transparent),
          ),
        ),
        Positioned(
          left: px.left,
          top: px.top,
          width: px.width,
          height: px.height,
          child: IgnorePointer(
            child: CustomPaint(
              painter: _BorderGridPainter(
                  rect: Rect.fromLTWH(0, 0, px.width, px.height)),
            ),
          ),
        ),
        _corner(size, _Corner.topLeft,
            left: px.left - _h / 2,
            top: px.top - _h / 2,
            onDrag: (d) {
              final dx = d.delta.dx / size.width,
                  dy = d.delta.dy / size.height;
              setState(() {
                final l =
                (_rect.left + dx).clamp(0.0, _rect.right - _min);
                final t =
                (_rect.top + dy).clamp(0.0, _rect.bottom - _min);
                _rect =
                    Rect.fromLTRB(l, t, _rect.right, _rect.bottom);
              });
              _emit();
            }),
        _corner(size, _Corner.topRight,
            left: px.right - _h / 2,
            top: px.top - _h / 2,
            onDrag: (d) {
              final dx = d.delta.dx / size.width,
                  dy = d.delta.dy / size.height;
              setState(() {
                final r = (_rect.right + dx)
                    .clamp(_rect.left + _min, 1.0);
                final t =
                (_rect.top + dy).clamp(0.0, _rect.bottom - _min);
                _rect =
                    Rect.fromLTRB(_rect.left, t, r, _rect.bottom);
              });
              _emit();
            }),
        _corner(size, _Corner.bottomLeft,
            left: px.left - _h / 2,
            top: px.bottom - _h / 2,
            onDrag: (d) {
              final dx = d.delta.dx / size.width,
                  dy = d.delta.dy / size.height;
              setState(() {
                final l =
                (_rect.left + dx).clamp(0.0, _rect.right - _min);
                final b = (_rect.bottom + dy)
                    .clamp(_rect.top + _min, 1.0);
                _rect =
                    Rect.fromLTRB(l, _rect.top, _rect.right, b);
              });
              _emit();
            }),
        _corner(size, _Corner.bottomRight,
            left: px.right - _h / 2,
            top: px.bottom - _h / 2,
            onDrag: (d) {
              final dx = d.delta.dx / size.width,
                  dy = d.delta.dy / size.height;
              setState(() {
                final r = (_rect.right + dx)
                    .clamp(_rect.left + _min, 1.0);
                final b = (_rect.bottom + dy)
                    .clamp(_rect.top + _min, 1.0);
                _rect =
                    Rect.fromLTRB(_rect.left, _rect.top, r, b);
              });
              _emit();
            }),
        _edge(
            left: px.left + px.width / 2 - _h / 2,
            top: px.top - _h / 2,
            horizontal: true,
            onDrag: (d) {
              final dy = d.delta.dy / size.height;
              setState(() {
                final t =
                (_rect.top + dy).clamp(0.0, _rect.bottom - _min);
                _rect = Rect.fromLTRB(
                    _rect.left, t, _rect.right, _rect.bottom);
              });
              _emit();
            }),
        _edge(
            left: px.left + px.width / 2 - _h / 2,
            top: px.bottom - _h / 2,
            horizontal: true,
            onDrag: (d) {
              final dy = d.delta.dy / size.height;
              setState(() {
                final b = (_rect.bottom + dy)
                    .clamp(_rect.top + _min, 1.0);
                _rect = Rect.fromLTRB(
                    _rect.left, _rect.top, _rect.right, b);
              });
              _emit();
            }),
        _edge(
            left: px.left - _h / 2,
            top: px.top + px.height / 2 - _h / 2,
            horizontal: false,
            onDrag: (d) {
              final dx = d.delta.dx / size.width;
              setState(() {
                final l =
                (_rect.left + dx).clamp(0.0, _rect.right - _min);
                _rect = Rect.fromLTRB(
                    l, _rect.top, _rect.right, _rect.bottom);
              });
              _emit();
            }),
        _edge(
            left: px.right - _h / 2,
            top: px.top + px.height / 2 - _h / 2,
            horizontal: false,
            onDrag: (d) {
              final dx = d.delta.dx / size.width;
              setState(() {
                final r = (_rect.right + dx)
                    .clamp(_rect.left + _min, 1.0);
                _rect = Rect.fromLTRB(
                    _rect.left, _rect.top, r, _rect.bottom);
              });
              _emit();
            }),
      ]);
    });
  }

  Widget _corner(Size size, _Corner c,
      {required double left,
        required double top,
        required void Function(DragUpdateDetails) onDrag}) {
    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onPanUpdate: onDrag,
        child: SizedBox(
          width: _h,
          height: _h,
          child: CustomPaint(painter: _CornerPainter(corner: c)),
        ),
      ),
    );
  }

  Widget _edge(
      {required double left,
        required double top,
        required bool horizontal,
        required void Function(DragUpdateDetails) onDrag}) {
    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onPanUpdate: onDrag,
        child: SizedBox(
          width: _h,
          height: _h,
          child: Center(
            child: Container(
              width: horizontal ? 24 : 4,
              height: horizontal ? 4 : 24,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _Corner { topLeft, topRight, bottomLeft, bottomRight }

class _DimPainter extends CustomPainter {
  final Rect cropRect;
  _DimPainter({required this.cropRect});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRect(cropRect)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(
        path, Paint()..color = Colors.black.withOpacity(0.55));
  }

  @override
  bool shouldRepaint(_DimPainter old) => old.cropRect != cropRect;
}

class _BorderGridPainter extends CustomPainter {
  final Rect rect;
  _BorderGridPainter({required this.rect});

  @override
  void paint(Canvas canvas, Size size) {
    final border = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height), border);
    final grid = Paint()
      ..color = Colors.white.withOpacity(0.25)
      ..strokeWidth = 0.8;
    canvas.drawLine(Offset(size.width / 3, 0),
        Offset(size.width / 3, size.height), grid);
    canvas.drawLine(Offset(size.width * 2 / 3, 0),
        Offset(size.width * 2 / 3, size.height), grid);
    canvas.drawLine(Offset(0, size.height / 3),
        Offset(size.width, size.height / 3), grid);
    canvas.drawLine(Offset(0, size.height * 2 / 3),
        Offset(size.width, size.height * 2 / 3), grid);
  }

  @override
  bool shouldRepaint(_BorderGridPainter old) => old.rect != rect;
}

class _CornerPainter extends CustomPainter {
  final _Corner corner;
  _CornerPainter({required this.corner});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final arm = math.min(size.width, size.height) * 0.55;
    late Offset pt, a, b;
    switch (corner) {
      case _Corner.topLeft:
        pt = Offset.zero;
        a = Offset(arm, 0);
        b = Offset(0, arm);
        break;
      case _Corner.topRight:
        pt = Offset(size.width, 0);
        a = Offset(size.width - arm, 0);
        b = Offset(size.width, arm);
        break;
      case _Corner.bottomLeft:
        pt = Offset(0, size.height);
        a = Offset(arm, size.height);
        b = Offset(0, size.height - arm);
        break;
      case _Corner.bottomRight:
        pt = Offset(size.width, size.height);
        a = Offset(size.width - arm, size.height);
        b = Offset(size.width, size.height - arm);
        break;
    }
    canvas.drawPath(
        Path()
          ..moveTo(a.dx, a.dy)
          ..lineTo(pt.dx, pt.dy)
          ..lineTo(b.dx, b.dy),
        paint);
  }

  @override
  bool shouldRepaint(_CornerPainter old) => old.corner != corner;
}


// // lib/widgets/video_question_widget.dart
//
// import 'dart:async';
// import 'dart:io';
// import 'dart:math' as math;
// import 'package:chewie/chewie.dart';
// import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
// import 'package:ffmpeg_kit_flutter_new/return_code.dart';
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'package:video_player/video_player.dart';
// import '../services/video_compression_service.dart';
// import '../providers/assessment_provider.dart';
// import '../models/api_response_model.dart';
// import '../Utils/ToastMessages.dart';
//
// class VideoQuestionWidget extends StatefulWidget {
//   final String qid;
//   final String aid;
//   final String sid;
//   final String questionDescription;
//   final AssessmentProvider provider;
//   final bool isOffline;
//
//   const VideoQuestionWidget({
//     Key? key,
//     required this.qid,
//     required this.aid,
//     required this.sid,
//     required this.questionDescription,
//     required this.provider,
//     this.isOffline = false,
//   }) : super(key: key);
//
//   @override
//   State<VideoQuestionWidget> createState() => _VideoQuestionWidgetState();
// }
//
// class _VideoQuestionWidgetState extends State<VideoQuestionWidget>
//     with SingleTickerProviderStateMixin {
//   final _compressionService = VideoCompressionService();
//   final Toast _toast = Toast();
//
//   // ── Compression/upload state ───────────────────────────────────────────────
//   File? _selectedVideo;
//   File? _compressedVideo;
//   double _compressionProgress = 0;
//   bool _isCompressing = false;
//   bool _isUploading = false;
//   VideoCompressionResult? _compressionResult;
//
//   // ── Preview controllers (for the LOCAL compressed video only) ─────────────
//   // These are NEVER used for the already-uploaded video playback.
//   // The uploaded video always opens in its own isolated dialog widget.
//   VideoPlayerController? _previewController;
//   ChewieController? _previewChewieController;
//
//   // ── Progress stream ────────────────────────────────────────────────────────
//   StreamSubscription<double>? _progressSub;
//
//   // ── Pulse animation for upload progress ───────────────────────────────────
//   late AnimationController _pulseController;
//   late Animation<double> _pulseAnimation;
//
//   @override
//   void initState() {
//     super.initState();
//     _pulseController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 900),
//     )
//       ..repeat(reverse: true);
//     _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
//       CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
//     );
//   }
//
//   @override
//   void dispose() {
//     _progressSub?.cancel();
//     _pulseController.dispose();
//     _disposePreviewControllers();
//     super.dispose();
//   }
//
//   void _disposePreviewControllers() {
//     _previewChewieController?.dispose();
//     _previewChewieController = null;
//     _previewController?.dispose();
//     _previewController = null;
//   }
//
//   // ── Uploaded video helpers ─────────────────────────────────────────────────
//
//   bool get _hasUploaded {
//     final list = widget.provider.videoList;
//     if (list == null || list.isEmpty) return false;
//     return list.any((v) => v.qid == widget.qid);
//   }
//
//   String? get _uploadedPath {
//     final list = widget.provider.videoList;
//     if (list == null || list.isEmpty) return null;
//     try {
//       return list
//           .firstWhere((v) => v.qid == widget.qid)
//           .doc_id;
//     } catch (_) {
//       return null;
//     }
//   }
//
//   // ── Picker ─────────────────────────────────────────────────────────────────
//
//   // ── PATCH for video_question_widget.dart ──────────────────────────────────────
// // Step 1: Add this import at the top of video_question_widget.dart
// //   import '../screens/video_trimmer_screen.dart';
// //
// // Step 2: Replace _showPickerSheet(), _pickVideo() with the code below.
// // Everything else in the file stays untouched.
// // ─────────────────────────────────────────────────────────────────────────────
//
//   // ── PATCH for video_question_widget.dart ──────────────────────────────────────
// //
// // 1. Add import at the top:
// //      import '../screens/video_trimmer_screen.dart';
// //
// // 2. Replace _showPickerSheet() and _pickVideo() with everything below.
// // ─────────────────────────────────────────────────────────────────────────────
//
//   void _showPickerSheet() {
//     showModalBottomSheet(
//       context: context,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (_) => SafeArea(
//         child: Wrap(children: [
//           Center(
//             child: Container(
//               margin: const EdgeInsets.only(top: 10),
//               width: 40, height: 4,
//               decoration: BoxDecoration(
//                   color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
//             ),
//           ),
//           const Padding(
//             padding: EdgeInsets.fromLTRB(20, 14, 20, 4),
//             child: Text('Select Video',
//                 style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//           ),
//           ListTile(
//             contentPadding: const EdgeInsets.symmetric(horizontal: 20),
//             leading: Container(
//               padding: const EdgeInsets.all(8),
//               decoration: BoxDecoration(
//                   color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)),
//               child: const Icon(Icons.videocam, color: Colors.blue),
//             ),
//             title: const Text('Record Video',
//                 style: TextStyle(fontWeight: FontWeight.w600)),
//             subtitle: const Text('Max 30 seconds'),
//             onTap: () {
//               Navigator.pop(context);
//               _pickVideo(ImageSource.camera); // camera — ImagePicker caps at 30s
//             },
//           ),
//           ListTile(
//             contentPadding: const EdgeInsets.symmetric(horizontal: 20),
//             leading: Container(
//               padding: const EdgeInsets.all(8),
//               decoration: BoxDecoration(
//                   color: Colors.purple.shade50, borderRadius: BorderRadius.circular(10)),
//               child: const Icon(Icons.video_library, color: Colors.purple),
//             ),
//             title: const Text('Choose from Gallery',
//                 style: TextStyle(fontWeight: FontWeight.w600)),
//             subtitle: const Text('Trim & crop before uploading'),
//             onTap: () {
//               Navigator.pop(context);
//               _pickVideoFromGallery(); // gallery — routes through trim+crop screen
//             },
//           ),
//           const SizedBox(height: 20),
//         ]),
//       ),
//     );
//   }
//
//   /// Camera: already capped at 30s by ImagePicker — no trimmer needed.
//   Future<void> _pickVideo(ImageSource source) async {
//     final picked = await ImagePicker().pickVideo(
//       source: source,
//       maxDuration: const Duration(seconds: 30),
//     );
//     if (picked == null || !mounted) return;
//
//     _disposePreviewControllers();
//     setState(() {
//       _selectedVideo = File(picked.path);
//       _compressedVideo = null;
//       _compressionResult = null;
//       _compressionProgress = 0;
//     });
//
//     await _compressVideo(picked.path);
//   }
//
//   /// Gallery: any length — show trim+crop screen, then compress the result.
//   Future<void> _pickVideoFromGallery() async {
//     final picked = await ImagePicker().pickVideo(
//       source: ImageSource.gallery,
//     );
//     if (picked == null || !mounted) return;
//
//     String pathToProcess = picked.path;
//
//     final tempVc = VideoPlayerController.file(File(picked.path));
//
//     try {
//       await tempVc.initialize();
//       final duration = tempVc.value.duration;
//       await tempVc.dispose();
//
//       if (!mounted) return;
//
//       const maxMs = 30 * 1000;
//
// // only open trim if truly longer than 30s
//       if (duration.inMilliseconds > maxMs + 200) {
//         final result = await VideoTrimmerScreen.show(
//           context,
//           picked.path,
//           maxSeconds: 30,
//         );
//
//         if (result == null || !mounted) return;
//         pathToProcess = result;
//       }
//
//     } catch (_) {
//       await tempVc.dispose();
//       if (!mounted) return;
//     }
//
//     _disposePreviewControllers();
//
//     setState(() {
//       _selectedVideo = File(pathToProcess);
//       _compressedVideo = null;
//       _compressionResult = null;
//       _compressionProgress = 0;
//     });
//
//     await _compressVideo(pathToProcess);
//   }
//   // ── Compression ────────────────────────────────────────────────────────────
//
//   Future<void> _compressVideo(String sourcePath) async {
//     setState(() {
//       _isCompressing = true;
//       _compressionProgress = 0;
//     });
//
//     _progressSub?.cancel();
//     _progressSub = _compressionService.progressStream.listen((p) {
//       if (mounted) setState(() => _compressionProgress = p);
//     });
//
//     try {
//       final result = await _compressionService.compressVideo(sourcePath);
//       _progressSub?.cancel();
//       if (!mounted) return;
//
//       if (result != null) {
//         setState(() => _isCompressing = false);
//         await _handleCompressedVideo(result);
//       } else {
//         // Cancelled
//         setState(() {
//           _isCompressing = false;
//           _selectedVideo = null;
//         });
//       }
//     } catch (e) {
//       _progressSub?.cancel();
//       if (mounted) {
//         setState(() {
//           _isCompressing = false;
//           _selectedVideo = null;
//         });
//         _toast.showErrorToast('Compression failed: $e');
//       }
//     }
//   }
//
//   Future<void> _cancelCompression() async {
//     await _compressionService.cancelCompression();
//     _progressSub?.cancel();
//     if (mounted) {
//       setState(() {
//         _isCompressing = false;
//         _selectedVideo = null;
//         _compressionProgress = 0;
//       });
//     }
//   }
//
//   // ── Route after compression ────────────────────────────────────────────────
//
//   Future<void> _handleCompressedVideo(VideoCompressionResult result) async {
//     if (widget.isOffline) {
//       // ── Copy to permanent storage first ────────────────────────────────
//       // Temp directory is cleared by OS — copy to documents directory
//       // so the file survives app restarts
//       File permanentFile;
//       try {
//         permanentFile = await _compressionService.copyToPermanentStorage(
//           result.file,
//           widget.aid,
//           widget.qid,
//         );
//       } catch (e) {
//         _toast.showErrorToast('Failed to save video: $e');
//         return;
//       }
//
//       // ── Save permanent path to SQLite ──────────────────────────────────
//       final APIResponse? res = await widget.provider.pickVideoOffline(
//         context,
//         widget.aid,
//         widget.qid,
//         permanentFile.path, // ← permanent path, not temp
//       );
//       if (!mounted) return;
//       if (res?.status?.toLowerCase() == 'success') {
//         _toast.showSuccessToast('Video saved locally');
//         await widget.provider.getVideosListOffline(context, widget.aid);
//         setState(() {
//           _selectedVideo = null;
//           _compressedVideo = null;
//           _compressionResult = null;
//         });
//       } else {
//         _toast.showErrorToast(res?.message ?? 'Failed to save video');
//       }
//     } else {
//       // ONLINE — show preview + upload button
//       setState(() {
//         _compressionResult = result;
//         _compressedVideo = result.file;
//       });
//       _initPreviewControllers(result.file.path);
//     }
//   }
//
//   // ── Local preview (for compressed video before upload) ────────────────────
//   // These controllers are ONLY for the pre-upload preview inside this card.
//   // They are completely separate from the dialog player.
//
//   void _initPreviewControllers(String path) {
//     _disposePreviewControllers();
//     _previewController = VideoPlayerController.file(File(path));
//     _previewController!.initialize().then((_) {
//       if (!mounted) return;
//       _previewChewieController = ChewieController(
//         videoPlayerController: _previewController!,
//         autoPlay: false,
//         looping: false,
//         aspectRatio: _previewController!.value.aspectRatio,
//         materialProgressColors: ChewieProgressColors(
//           playedColor: Colors.blue,
//           handleColor: Colors.blueAccent,
//           bufferedColor: Colors.blue.shade100,
//           backgroundColor: Colors.grey.shade300,
//         ),
//       );
//       if (mounted) setState(() {});
//     });
//   }
//
//   // ── Upload (online only) ───────────────────────────────────────────────────
//
//   Future<void> _uploadVideo() async {
//     if (_compressedVideo == null) return;
//     setState(() => _isUploading = true);
//
//     final filename =
//         'video_${widget.qid}_${DateTime
//         .now()
//         .millisecondsSinceEpoch}.mp4';
//
//     final APIResponse? res = await widget.provider.uploadVideo(
//       context,
//       widget.aid,
//       widget.qid,
//       widget.sid,
//       filename,
//       _compressedVideo!,
//     );
//
//     if (!mounted) return;
//     setState(() => _isUploading = false);
//
//     if (res?.status?.toLowerCase() == 'success') {
//       _toast.showSuccessToast(res!.message ?? 'Video uploaded successfully');
//       _disposePreviewControllers();
//       setState(() {
//         _selectedVideo = null;
//         _compressedVideo = null;
//         _compressionResult = null;
//       });
//       await widget.provider.getVideosList(context, widget.aid);
//     } else {
//       _toast.showErrorToast(res?.message ?? 'Upload failed');
//     }
//   }
//
//   // ── Play uploaded video ────────────────────────────────────────────────────
//   // Opens in a fully self-contained dialog that manages its own controllers.
//   // Nothing shared with this widget's state — no disposal conflict possible.
//
//   Future<void> _openUploadedVideo() async {
//     final path = _uploadedPath;
//     if (path == null) return;
//
//     if (widget.isOffline) {
//       // Play local file in isolated dialog
//       await showDialog(
//         context: context,
//         builder: (ctx) => _VideoPlayerDialog(filePath: path),
//       );
//     } else {
//       // Open server URL in external player
//       final url =
//           'https://apps.slichealth.com/ords/ihmis_admin/assesment/video?doc_id=$path';
//       if (await canLaunchUrl(Uri.parse(url))) {
//         await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
//       } else {
//         _toast.showErrorToast('Could not open video');
//       }
//     }
//   }
//
//   // ── Delete ─────────────────────────────────────────────────────────────────
//
//   Future<void> _deleteUploadedVideo() async {
//     final confirm = await showDialog<bool>(
//       context: context,
//       builder: (ctx) =>
//           AlertDialog(
//             title: const Text('Delete Video'),
//             content: const Text('Are you sure you want to delete this video?'),
//             actions: [
//               TextButton(
//                   onPressed: () => Navigator.pop(ctx, false),
//                   child: const Text('Cancel')),
//               TextButton(
//                   onPressed: () => Navigator.pop(ctx, true),
//                   style: TextButton.styleFrom(foregroundColor: Colors.red),
//                   child: const Text('Delete')),
//             ],
//           ),
//     );
//     if (confirm != true || !mounted) return;
//
//     if (widget.isOffline) {
//       final res = await widget.provider
//           .deleteVideoOffline(context, widget.aid, widget.qid);
//       if (!mounted) return;
//       if (res.status?.toLowerCase() == 'success') {
//         _toast.showSuccessToast('Video deleted');
//         await widget.provider.getVideosListOffline(context, widget.aid);
//       } else {
//         _toast.showErrorToast(res.message ?? 'Delete failed');
//       }
//     } else {
//       final res =
//       await widget.provider.deleteVideo(context, widget.aid, widget.qid);
//       if (!mounted) return;
//       if (res.status?.toLowerCase() == 'success') {
//         _toast.showSuccessToast('Video deleted');
//         await widget.provider.getVideosList(context, widget.aid);
//       } else {
//         _toast.showErrorToast(res.message ?? 'Delete failed');
//       }
//     }
//   }
//
//   // ── Build ──────────────────────────────────────────────────────────────────
//
//   @override
//   Widget build(BuildContext context) {
//     return SafeArea(
//       child: Card(
//         margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
//         elevation: 2,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
//         child: Padding(
//           padding: const EdgeInsets.all(14),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Question title
//               Row(children: [
//                 const Icon(Icons.videocam_outlined, size: 18, color: Colors.blue),
//                 const SizedBox(width: 8),
//                 Expanded(
//                   child: Text(
//                     widget.questionDescription,
//                     style: const TextStyle(
//                         fontSize: 14, fontWeight: FontWeight.w600),
//                   ),
//                 ),
//               ]),
//               const SizedBox(height: 14),
//
//               // Already uploaded — shows badge with play/replace/delete
//               if (_hasUploaded && _selectedVideo == null)
//                 _buildUploadedBadge(),
//
//               // Compressing
//               if (_isCompressing) _buildCompressionProgress(),
//
//               // After compression — stats + preview + actions
//               if (!_isCompressing && _compressedVideo != null) ...[
//                 _buildCompressionStats(),
//                 const SizedBox(height: 10),
//                 // Local preview of compressed video (before upload)
//                 if (_previewChewieController != null) _buildLocalPreview(),
//                 const SizedBox(height: 12),
//                 if (_isUploading)
//                   _buildUploadProgress()
//                 else
//                   _buildPostCompressionActions(),
//               ],
//
//               // Initial pick button
//               if (_selectedVideo == null && !_isCompressing && !_hasUploaded)
//                 _buildPickButton(),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   // ── Sub-widgets ────────────────────────────────────────────────────────────
//
//   Widget _buildPickButton() =>
//       Center(
//         child: OutlinedButton.icon(
//           onPressed: _showPickerSheet,
//           icon: const Icon(Icons.video_call),
//           label: const Text('Upload Video'),
//           style: OutlinedButton.styleFrom(
//             foregroundColor: Colors.blue,
//             side: const BorderSide(color: Colors.blue),
//             padding:
//             const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//             shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(10)),
//           ),
//         ),
//       );
//
//   Widget _buildCompressionProgress() =>
//       Container(
//         padding: const EdgeInsets.all(12),
//         decoration: BoxDecoration(
//           color: Colors.orange.shade50,
//           borderRadius: BorderRadius.circular(10),
//           border: Border.all(color: Colors.orange.shade200),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(children: [
//               const Icon(Icons.compress, size: 16, color: Colors.orange),
//               const SizedBox(width: 8),
//               Text('Compressing video...',
//                   style: GoogleFonts.poppins(
//                       fontSize: 12,
//                       color: Colors.orange.shade800,
//                       fontWeight: FontWeight.w600)),
//               const Spacer(),
//               Text(
//                 '${(_compressionProgress * 100).toStringAsFixed(0)}%',
//                 style: GoogleFonts.poppins(
//                     fontSize: 13,
//                     color: Colors.orange.shade800,
//                     fontWeight: FontWeight.bold),
//               ),
//             ]),
//             const SizedBox(height: 8),
//             ClipRRect(
//               borderRadius: BorderRadius.circular(6),
//               child: LinearProgressIndicator(
//                 value: _compressionProgress,
//                 backgroundColor: Colors.orange.shade100,
//                 valueColor: const AlwaysStoppedAnimation(Colors.orange),
//                 minHeight: 8,
//               ),
//             ),
//             const SizedBox(height: 6),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text('Optimizing for upload — do not close the app',
//                     style: TextStyle(
//                         fontSize: 10, color: Colors.grey.shade600)),
//                 TextButton.icon(
//                   onPressed: _cancelCompression,
//                   icon: const Icon(Icons.close, size: 12),
//                   label:
//                   const Text('Cancel', style: TextStyle(fontSize: 11)),
//                   style: TextButton.styleFrom(
//                     foregroundColor: Colors.red,
//                     padding: EdgeInsets.zero,
//                     minimumSize: Size.zero,
//                     tapTargetSize: MaterialTapTargetSize.shrinkWrap,
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       );
//
//   Widget _buildCompressionStats() {
//     if (_compressionResult == null) return const SizedBox();
//     final savedMB = ((_compressionResult!.originalSizeBytes -
//         _compressionResult!.compressedSizeBytes) /
//         1024 /
//         1024)
//         .toStringAsFixed(1);
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//       decoration: BoxDecoration(
//         color: Colors.green.shade50,
//         borderRadius: BorderRadius.circular(10),
//         border: Border.all(color: Colors.green.shade200),
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceAround,
//         children: [
//           _stat('Before', '${_compressionResult!.originalSizeMB} MB',
//               Icons.file_present, Colors.grey.shade600),
//           Icon(Icons.arrow_forward, size: 14, color: Colors.grey.shade400),
//           _stat('After', '${_compressionResult!.compressedSizeMB} MB',
//               Icons.compress, Colors.green.shade700),
//           _stat('Saved', '$savedMB MB', Icons.savings, Colors.blue.shade700),
//           _stat('Ratio', '${_compressionResult!.ratio.toStringAsFixed(1)}×',
//               Icons.speed, Colors.purple.shade700),
//         ],
//       ),
//     );
//   }
//
//   Widget _stat(String label, String value, IconData icon, Color color) =>
//       Column(mainAxisSize: MainAxisSize.min, children: [
//         Icon(icon, size: 14, color: color),
//         const SizedBox(height: 2),
//         Text(label,
//             style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
//         Text(value,
//             style: TextStyle(
//                 fontSize: 11, fontWeight: FontWeight.bold, color: color)),
//       ]);
//
//   // Local preview of the compressed file (before upload)
//   Widget _buildLocalPreview() =>
//       ClipRRect(
//         borderRadius: BorderRadius.circular(10),
//         child: AspectRatio(
//           aspectRatio: _previewController!.value.aspectRatio,
//           child: Chewie(controller: _previewChewieController!),
//         ),
//       );
//
//   Widget _buildPostCompressionActions() =>
//       Row(children: [
//         OutlinedButton.icon(
//           onPressed: _showPickerSheet,
//           icon: const Icon(Icons.refresh, size: 16),
//           label: const Text('Re-pick'),
//           style: OutlinedButton.styleFrom(
//             foregroundColor: Colors.grey.shade700,
//             side: BorderSide(color: Colors.grey.shade400),
//             padding:
//             const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
//             shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(10)),
//           ),
//         ),
//         const SizedBox(width: 10),
//         Expanded(
//           child: ElevatedButton.icon(
//             onPressed: _uploadVideo,
//             icon: const Icon(Icons.cloud_upload),
//             label: const Text('Upload Video'),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.blue,
//               foregroundColor: Colors.white,
//               padding: const EdgeInsets.symmetric(vertical: 12),
//               shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(10)),
//               elevation: 2,
//             ),
//           ),
//         ),
//       ]);
//
//   Widget _buildUploadProgress() {
//     final progress = widget.provider.uploadVideoProgress;
//     final totalBytes = _compressedVideo?.lengthSync() ?? 0;
//     final uploadedMB =
//     (totalBytes / 1024 / 1024 * progress).toStringAsFixed(1);
//     final totalMB = (totalBytes / 1024 / 1024).toStringAsFixed(1);
//
//     return Container(
//       padding: const EdgeInsets.all(14),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [Colors.blue.shade50, Colors.blue.shade100],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.blue.shade200),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(children: [
//             ScaleTransition(
//               scale: _pulseAnimation,
//               child: Container(
//                 padding: const EdgeInsets.all(6),
//                 decoration: BoxDecoration(
//                   color: Colors.blue,
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: const Icon(Icons.cloud_upload,
//                     color: Colors.white, size: 16),
//               ),
//             ),
//             const SizedBox(width: 10),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text('Uploading to server...',
//                       style: GoogleFonts.poppins(
//                           fontSize: 13,
//                           fontWeight: FontWeight.w600,
//                           color: Colors.blue.shade800)),
//                   Text('Please keep the app open',
//                       style: TextStyle(
//                           fontSize: 10, color: Colors.blue.shade600)),
//                 ],
//               ),
//             ),
//             Container(
//               padding:
//               const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//               decoration: BoxDecoration(
//                 color: Colors.blue,
//                 borderRadius: BorderRadius.circular(20),
//               ),
//               child: Text(
//                 '${(progress * 100).toStringAsFixed(0)}%',
//                 style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 13,
//                     fontWeight: FontWeight.bold),
//               ),
//             ),
//           ]),
//           const SizedBox(height: 12),
//           ClipRRect(
//             borderRadius: BorderRadius.circular(8),
//             child: LinearProgressIndicator(
//               value: progress,
//               backgroundColor: Colors.blue.shade100,
//               valueColor: AlwaysStoppedAnimation(Colors.blue.shade600),
//               minHeight: 10,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text('$uploadedMB MB / $totalMB MB',
//                   style: TextStyle(
//                       fontSize: 11,
//                       color: Colors.blue.shade700,
//                       fontWeight: FontWeight.w500)),
//               if (progress < 1.0)
//                 Row(children: [
//                   SizedBox(
//                     width: 10,
//                     height: 10,
//                     child: CircularProgressIndicator(
//                         strokeWidth: 1.5, color: Colors.blue.shade600),
//                   ),
//                   const SizedBox(width: 4),
//                   Text('Sending...',
//                       style: TextStyle(
//                           fontSize: 10, color: Colors.blue.shade600)),
//                 ])
//               else
//                 Row(children: [
//                   const Icon(Icons.check_circle,
//                       size: 14, color: Colors.green),
//                   const SizedBox(width: 4),
//                   Text('Done',
//                       style: TextStyle(
//                           fontSize: 10,
//                           color: Colors.green.shade700,
//                           fontWeight: FontWeight.w600)),
//                 ]),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildUploadedBadge() =>
//       Padding(
//         padding: const EdgeInsets.only(bottom: 10),
//         child: Row(children: [
//           Expanded(
//             child: InkWell(
//               onTap: _openUploadedVideo,
//               borderRadius: BorderRadius.circular(10),
//               child: Container(
//                 padding: const EdgeInsets.symmetric(
//                     horizontal: 12, vertical: 10),
//                 decoration: BoxDecoration(
//                   color: Colors.green.shade50,
//                   borderRadius: BorderRadius.circular(10),
//                   border: Border.all(color: Colors.green.shade300),
//                 ),
//                 child: Row(children: [
//                   const Icon(Icons.check_circle,
//                       color: Colors.green, size: 20),
//                   const SizedBox(width: 8),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           widget.isOffline
//                               ? 'Video saved locally'
//                               : 'Video uploaded',
//                           style: const TextStyle(
//                               color: Colors.green,
//                               fontWeight: FontWeight.w700,
//                               fontSize: 13),
//                         ),
//                         Text('Tap to play',
//                             style: TextStyle(
//                                 fontSize: 10,
//                                 color: Colors.green.shade600)),
//                       ],
//                     ),
//                   ),
//                   Container(
//                     padding: const EdgeInsets.symmetric(
//                         horizontal: 10, vertical: 5),
//                     decoration: BoxDecoration(
//                       color: Colors.blue,
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     child: const Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Icon(Icons.play_arrow,
//                             color: Colors.white, size: 14),
//                         SizedBox(width: 4),
//                         Text('PLAY',
//                             style: TextStyle(
//                                 color: Colors.white,
//                                 fontSize: 11,
//                                 fontWeight: FontWeight.bold)),
//                       ],
//                     ),
//                   ),
//                 ]),
//               ),
//             ),
//           ),
//           const SizedBox(width: 8),
//           _iconAction(
//             icon: Icons.swap_horiz,
//             color: Colors.orange,
//             tooltip: 'Replace',
//             onTap: _showPickerSheet,
//           ),
//           const SizedBox(width: 6),
//           widget.provider.isLoadingVideoDelete == true
//               ? const SizedBox(
//             width: 36,
//             height: 36,
//             child: Center(
//               child: SizedBox(
//                 width: 20,
//                 height: 20,
//                 child: CircularProgressIndicator(strokeWidth: 2),
//               ),
//             ),
//           )
//               : _iconAction(
//             icon: Icons.delete_outline,
//             color: Colors.red,
//             tooltip: 'Delete',
//             onTap: _deleteUploadedVideo,
//           ),
//         ]),
//       );
//
//   Widget _iconAction({
//     required IconData icon,
//     required Color color,
//     required String tooltip,
//     required VoidCallback onTap,
//   }) =>
//       Tooltip(
//         message: tooltip,
//         child: InkWell(
//           onTap: onTap,
//           borderRadius: BorderRadius.circular(8),
//           child: Container(
//             padding: const EdgeInsets.all(8),
//             decoration: BoxDecoration(
//               border: Border.all(color: color.withOpacity(0.4)),
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: Icon(icon, color: color, size: 20),
//           ),
//         ),
//       );
// }
//
// // ── Isolated video player dialog ───────────────────────────────────────────
// // Fully self-contained — creates and disposes its own controllers.
// // Zero shared state with VideoQuestionWidget. No disposal conflicts possible.
//
// class _VideoPlayerDialog extends StatefulWidget {
//   final String filePath;
//
//   const _VideoPlayerDialog({required this.filePath});
//
//   @override
//   State<_VideoPlayerDialog> createState() => _VideoPlayerDialogState();
// }
//
// class _VideoPlayerDialogState extends State<_VideoPlayerDialog> {
//   VideoPlayerController? _controller;
//   ChewieController? _chewieController;
//   bool _initialized = false;
//   String? _error;
//
//   @override
//   void initState() {
//     super.initState();
//     _initPlayer();
//   }
//
//   Future<void> _initPlayer() async {
//     try {
//       final file = File(widget.filePath);
//
//       // ── Guard: file must exist ─────────────────────────────────────────
//       if (!await file.exists()) {
//         if (mounted) {
//           setState(() =>
//           _error =
//           'Video file not found.\nThe file may have been moved or deleted.\n\nPath: ${widget
//               .filePath}');
//         }
//         return;
//       }
//
//       _controller = VideoPlayerController.file(file);
//       await _controller!.initialize();
//
//       if (!mounted) return;
//
//       _chewieController = ChewieController(
//         videoPlayerController: _controller!,
//         autoPlay: true,
//         looping: false,
//         aspectRatio: _controller!.value.aspectRatio,
//         materialProgressColors: ChewieProgressColors(
//           playedColor: Colors.blue,
//           handleColor: Colors.blueAccent,
//           bufferedColor: Colors.blue.shade100,
//           backgroundColor: Colors.grey.shade800,
//         ),
//       );
//
//       setState(() => _initialized = true);
//     } catch (e) {
//       if (mounted) setState(() => _error = e.toString());
//     }
//   }
//
//   @override
//   void dispose() {
//     // Always dispose Chewie before VideoPlayerController
//     _chewieController?.dispose();
//     _controller?.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Dialog(
//       backgroundColor: Colors.black,
//       insetPadding: const EdgeInsets.all(16),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           // Header
//           Padding(
//             padding:
//             const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//             child: Row(children: [
//               const Icon(Icons.videocam, color: Colors.white, size: 18),
//               const SizedBox(width: 8),
//               const Expanded(
//                 child: Text('Video Preview',
//                     style: TextStyle(
//                         color: Colors.white,
//                         fontWeight: FontWeight.w600,
//                         fontSize: 14)),
//               ),
//               IconButton(
//                 onPressed: () => Navigator.pop(context),
//                 icon: const Icon(Icons.close, color: Colors.white),
//                 padding: EdgeInsets.zero,
//                 constraints: const BoxConstraints(),
//               ),
//             ]),
//           ),
//           const Divider(color: Colors.white24, height: 1),
//
//           // Player
//           if (_error != null)
//             Padding(
//               padding: const EdgeInsets.all(24),
//               child: Column(children: [
//                 const Icon(Icons.error_outline,
//                     color: Colors.red, size: 40),
//                 const SizedBox(height: 8),
//                 Text('Could not play video',
//                     style: const TextStyle(
//                         color: Colors.white, fontWeight: FontWeight.w600)),
//                 const SizedBox(height: 4),
//                 Text(_error!,
//                     style: const TextStyle(
//                         color: Colors.white54, fontSize: 11),
//                     textAlign: TextAlign.center),
//               ]),
//             )
//           else
//             if (!_initialized)
//               const Padding(
//                 padding: EdgeInsets.symmetric(vertical: 40),
//                 child: Column(children: [
//                   CircularProgressIndicator(color: Colors.blue),
//                   SizedBox(height: 12),
//                   Text('Loading video...',
//                       style: TextStyle(color: Colors.white54, fontSize: 12)),
//                 ]),
//               )
//             else
//               ClipRRect(
//                 borderRadius: const BorderRadius.only(
//                   bottomLeft: Radius.circular(12),
//                   bottomRight: Radius.circular(12),
//                 ),
//                 child: AspectRatio(
//                   aspectRatio: _controller!.value.aspectRatio,
//                   child: Chewie(controller: _chewieController!),
//                 ),
//               ),
//         ],
//       ),
//     );
//   }
// }
//
// // lib/screens/video_trimmer_screen.dart
// // No dependency on video_trimmer package — uses VideoPlayerController directly.
// // Uses ffmpeg_kit_flutter_min_gpl for trim + crop processing.
//
//
// class VideoTrimmerScreen extends StatefulWidget {
//   final String videoPath;
//   final int maxDurationSeconds;
//
//   const VideoTrimmerScreen({
//     Key? key,
//     required this.videoPath,
//     this.maxDurationSeconds = 30,
//   }) : super(key: key);
//
//   static Future<String?> show(BuildContext context, String videoPath,
//       {int maxSeconds = 30}) {
//     return Navigator.push<String>(
//       context,
//       MaterialPageRoute(
//         fullscreenDialog: true,
//         builder: (_) => VideoTrimmerScreen(
//           videoPath: videoPath,
//           maxDurationSeconds: maxSeconds,
//         ),
//       ),
//     );
//   }
//
//   @override
//   State<VideoTrimmerScreen> createState() => _VideoTrimmerScreenState();
// }
//
// enum _Step { trim, crop, processing }
//
// class _VideoTrimmerScreenState extends State<VideoTrimmerScreen> {
//   // ── Video ──────────────────────────────────────────────────────────────────
//   VideoPlayerController? _mainController;
//   Duration _totalDuration = Duration.zero;
//
//   // ── Trim state (in seconds, double) ───────────────────────────────────────
//   double _trimStart = 0.0;
//   double _trimEnd = 0.0;
//
//   // ── Playback position tracking ─────────────────────────────────────────────
//   Duration _position = Duration.zero;
//
//   // ── Step & loading ─────────────────────────────────────────────────────────
//   _Step _step = _Step.trim;
//   bool _isLoading = true;
//   String? _errorMsg;
//   String _processingLabel = 'Processing...';
//
//   // ── Video dimensions (for crop pixel math) ─────────────────────────────────
//   int _videoWidth = 0;
//   int _videoHeight = 0;
//
//   // ── Crop ───────────────────────────────────────────────────────────────────
//   Rect _cropRect = const Rect.fromLTWH(0.05, 0.05, 0.9, 0.9);
//   final GlobalKey _previewKey = GlobalKey();
//   Size _previewSize = Size.zero;
//   VideoPlayerController? _cropPreviewController;
//
//   @override
//   void initState() {
//     super.initState();
//     _loadVideo();
//   }
//
//   @override
//   void dispose() {
//     _mainController?.dispose();
//     _cropPreviewController?.dispose();
//     super.dispose();
//   }
//
//   // ── Load ───────────────────────────────────────────────────────────────────
//
//   Future<void> _loadVideo() async {
//     try {
//       final controller =
//       VideoPlayerController.file(File(widget.videoPath));
//       await controller.initialize();
//
//       final duration = controller.value.duration;
//       final size = controller.value.size;
//
//       // Track position for the scrubber needle
//       controller.addListener(() {
//         if (mounted) setState(() => _position = controller.value.position);
//       });
//
//       setState(() {
//         _mainController = controller;
//         _totalDuration = duration;
//         _trimStart = 0.0;
//         _trimEnd = math.min(
//           duration.inMilliseconds.toDouble(),
//           widget.maxDurationSeconds * 1000.0,
//         );
//         _videoWidth = size.width.round();
//         _videoHeight = size.height.round();
//         _isLoading = false;
//       });
//     } catch (e) {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//           _errorMsg = e.toString();
//         });
//       }
//     }
//   }
//
//   // ── Helpers ────────────────────────────────────────────────────────────────
//
//   double get _selectedSeconds => (_trimEnd - _trimStart) / 1000.0;
//   double get _totalSeconds => _totalDuration.inMilliseconds / 1000.0;
//
//   bool get _trimValid =>
//       _selectedSeconds > 0.5 &&
//           _selectedSeconds <= widget.maxDurationSeconds;
//
//   String _fmt(double seconds) {
//     final s = seconds.round();
//     return '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
//   }
//
//   // ── Scrubber seek ──────────────────────────────────────────────────────────
//
//   void _seekTo(double ms) {
//     _mainController?.seekTo(Duration(milliseconds: ms.round()));
//   }
//
//   // ── Trim → Crop ────────────────────────────────────────────────────────────
//
//   Future<void> _advanceToCrop() async {
//     if (!_trimValid) return;
//     _mainController?.pause();
//
//     setState(() {
//       _step = _Step.processing;
//       _processingLabel = 'Preparing crop preview...';
//     });
//
//     final dir = await getTemporaryDirectory();
//     final trimPath =
//         '${dir.path}/trim_prev_${DateTime.now().millisecondsSinceEpoch}.mp4';
//     final startSec = _trimStart / 1000.0;
//     final durSec = (_trimEnd - _trimStart) / 1000.0;
//
//     final session = await FFmpegKit.execute(
//         '-y -i "${widget.videoPath}" -ss $startSec -t $durSec -c copy "$trimPath"');
//     final rc = await session.getReturnCode();
//     if (!mounted) return;
//
//     if (ReturnCode.isSuccess(rc)) {
//       _cropPreviewController?.dispose();
//       _cropPreviewController =
//           VideoPlayerController.file(File(trimPath));
//       await _cropPreviewController!.initialize();
//       await _cropPreviewController!.setLooping(true);
//       await _cropPreviewController!.play();
//
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         final box = _previewKey.currentContext?.findRenderObject()
//         as RenderBox?;
//         if (box != null && mounted) {
//           setState(() => _previewSize = box.size);
//         }
//       });
//
//       setState(() => _step = _Step.crop);
//     } else {
//       setState(() {
//         _step = _Step.trim;
//         _errorMsg = 'Preview generation failed — try a shorter clip';
//       });
//     }
//   }
//
//   // ── Apply trim + crop ──────────────────────────────────────────────────────
//
//   Future<void> _applyAndReturn() async {
//     setState(() {
//       _step = _Step.processing;
//       _processingLabel = 'Applying trim & crop...';
//     });
//     _cropPreviewController?.pause();
//
//     final dir = await getTemporaryDirectory();
//     final out =
//         '${dir.path}/out_${DateTime.now().millisecondsSinceEpoch}.mp4';
//
//     final c = _cropPixels();
//     final startSec = _trimStart / 1000.0;
//     final durSec = (_trimEnd - _trimStart) / 1000.0;
//
//     // final cmd = '-y -i "${widget.videoPath}" '
//     //     '-ss $startSec -t $durSec '
//     //     '-vf "crop=${c['w']}:${c['h']}:${c['x']}:${c['y']}" '
//     //     '-c:v libx264 -preset fast -crf 23 -c:a aac '
//     //     '"$out"';
//
//     final cmd = '-y -i "${widget.videoPath}" '
//         '-ss $startSec -t $durSec '
//         '-c copy '
//         '"$out"';
//
//     final session = await FFmpegKit.execute(cmd);
//     final rc = await session.getReturnCode();
//     if (!mounted) return;
//
//     if (ReturnCode.isSuccess(rc)) {
//       Navigator.pop(context, out);
//     } else {
//       setState(() => _step = _Step.crop);
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Processing failed — try again'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }
//
//   // ── Crop pixel math ────────────────────────────────────────────────────────
//
//   Map<String, int> _cropPixels() {
//     final vw = _videoWidth.toDouble();
//     final vh = _videoHeight.toDouble();
//     final pw = _previewSize.width;
//     final ph = _previewSize.height;
//
//     if (pw == 0 || ph == 0) {
//       return {'x': 0, 'y': 0, 'w': _videoWidth, 'h': _videoHeight};
//     }
//
//     final videoAspect = vw / vh;
//     final previewAspect = pw / ph;
//
//     double renderW, renderH, offsetX, offsetY;
//     if (videoAspect > previewAspect) {
//       renderW = pw;
//       renderH = pw / videoAspect;
//       offsetX = 0;
//       offsetY = (ph - renderH) / 2;
//     } else {
//       renderH = ph;
//       renderW = ph * videoAspect;
//       offsetX = (pw - renderW) / 2;
//       offsetY = 0;
//     }
//
//     final cL =
//     ((_cropRect.left * pw) - offsetX).clamp(0.0, renderW);
//     final cT =
//     ((_cropRect.top * ph) - offsetY).clamp(0.0, renderH);
//     final cR =
//     ((_cropRect.right * pw) - offsetX).clamp(0.0, renderW);
//     final cB =
//     ((_cropRect.bottom * ph) - offsetY).clamp(0.0, renderH);
//
//     final scaleX = vw / renderW;
//     final scaleY = vh / renderH;
//
//     final x = (cL * scaleX).round();
//     final y = (cT * scaleY).round();
//     var w = ((cR - cL) * scaleX).round();
//     var h = ((cB - cT) * scaleY).round();
//     w = math.max((w ~/ 2) * 2, 2);
//     h = math.max((h ~/ 2) * 2, 2);
//
//     return {'x': x, 'y': y, 'w': w, 'h': h};
//   }
//
//   // ── Build ──────────────────────────────────────────────────────────────────
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       appBar: _buildAppBar(),
//       body: _isLoading
//           ? _buildSpinner('Loading video...')
//           : _errorMsg != null
//           ? _buildError()
//           : _step == _Step.processing
//           ? _buildSpinner(_processingLabel)
//           : _step == _Step.trim
//           ? _buildTrimStep()
//           : _buildCropStep(),
//     );
//   }
//
//   // ── AppBar ─────────────────────────────────────────────────────────────────
//
//   AppBar _buildAppBar() {
//     String title;
//     Widget? action;
//     VoidCallback? onBack;
//
//     switch (_step) {
//       case _Step.trim:
//         title = 'Step 1 of 2 — Trim';
//         action = TextButton(
//           onPressed: _trimValid ? _advanceToCrop : null,
//           child: Text(
//             'Next →',
//             style: TextStyle(
//               color: _trimValid ? Colors.blue : Colors.grey.shade600,
//               fontWeight: FontWeight.bold,
//               fontSize: 15,
//             ),
//           ),
//         );
//         break;
//       case _Step.crop:
//         title = 'Step 2 of 2 — Crop';
//         action = TextButton(
//           onPressed: _applyAndReturn,
//           child: const Text(
//             'Done',
//             style: TextStyle(
//               color: Colors.blue,
//               fontWeight: FontWeight.bold,
//               fontSize: 15,
//             ),
//           ),
//         );
//         onBack = () {
//           _cropPreviewController?.pause();
//           setState(() => _step = _Step.trim);
//         };
//         break;
//       case _Step.processing:
//         title = 'Processing...';
//         break;
//     }
//
//     return AppBar(
//       backgroundColor: Colors.black,
//       foregroundColor: Colors.white,
//       elevation: 0,
//       leading: onBack != null
//           ? IconButton(
//           icon: const Icon(Icons.arrow_back), onPressed: onBack)
//           : _step == _Step.trim
//           ? IconButton(
//         icon: const Icon(Icons.close),
//         onPressed: () => Navigator.pop(context, null),
//       )
//           : null,
//       title: Text(title,
//           style: const TextStyle(
//               fontSize: 15, fontWeight: FontWeight.w600)),
//       actions: [if (action != null) action],
//     );
//   }
//
//   // ── Shared ─────────────────────────────────────────────────────────────────
//
//   Widget _buildSpinner(String label) => Center(
//     child: Column(mainAxisSize: MainAxisSize.min, children: [
//       const CircularProgressIndicator(color: Colors.blue),
//       const SizedBox(height: 16),
//       Text(label,
//           style: const TextStyle(color: Colors.white, fontSize: 14)),
//     ]),
//   );
//
//   Widget _buildError() => Center(
//     child: Padding(
//       padding: const EdgeInsets.all(24),
//       child: Column(mainAxisSize: MainAxisSize.min, children: [
//         const Icon(Icons.error_outline, color: Colors.red, size: 48),
//         const SizedBox(height: 12),
//         Text(_errorMsg ?? 'Unknown error',
//             style: const TextStyle(
//                 color: Colors.white54, fontSize: 12),
//             textAlign: TextAlign.center),
//         const SizedBox(height: 16),
//         ElevatedButton(
//           onPressed: () => setState(() {
//             _errorMsg = null;
//             _step = _Step.trim;
//           }),
//           child: const Text('Dismiss'),
//         ),
//       ]),
//     ),
//   );
//
//   // ══════════════════════════════════════════════════════════════════════════
//   // STEP 1: TRIM
//   // ══════════════════════════════════════════════════════════════════════════
//
//   Widget _buildTrimStep() {
//     final isOver = _selectedSeconds > widget.maxDurationSeconds;
//     final isReady = _totalDuration > Duration.zero;
//
//     return Column(children: [
//       // ── Video preview ────────────────────────────────────────────────────
//       Expanded(
//         child: GestureDetector(
//           onTap: () {
//             if (_mainController == null) return;
//             if (_mainController!.value.isPlaying) {
//               _mainController!.pause();
//             } else {
//               // Only play within the trim range
//               final pos = _mainController!.value.position.inMilliseconds;
//               if (pos < _trimStart || pos >= _trimEnd) {
//                 _mainController!.seekTo(
//                     Duration(milliseconds: _trimStart.round()));
//               }
//               _mainController!.play();
//             }
//             setState(() {});
//           },
//           child: Stack(alignment: Alignment.center, children: [
//             _mainController != null &&
//                 _mainController!.value.isInitialized
//                 ? Center(
//               child: AspectRatio(
//                 aspectRatio:
//                 _mainController!.value.aspectRatio,
//                 child: VideoPlayer(_mainController!),
//               ),
//             )
//                 : const SizedBox(),
//             // Play/pause overlay
//             if (_mainController != null &&
//                 !_mainController!.value.isPlaying)
//               Container(
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: Colors.black.withOpacity(0.5),
//                   shape: BoxShape.circle,
//                 ),
//                 child: const Icon(Icons.play_arrow,
//                     color: Colors.white, size: 40),
//               ),
//           ]),
//         ),
//       ),
//
//       // ── Duration pill ─────────────────────────────────────────────────
//       Padding(
//         padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
//         child: Center(
//           child: Container(
//             padding:
//             const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
//             decoration: BoxDecoration(
//               color: isOver
//                   ? Colors.orange.withOpacity(0.15)
//                   : Colors.blue.withOpacity(0.15),
//               borderRadius: BorderRadius.circular(20),
//               border: Border.all(
//                 color: isOver
//                     ? Colors.orange.withOpacity(0.5)
//                     : Colors.blue.withOpacity(0.4),
//               ),
//             ),
//             child: Row(mainAxisSize: MainAxisSize.min, children: [
//               Icon(
//                 isOver
//                     ? Icons.warning_amber_rounded
//                     : Icons.timer_outlined,
//                 size: 14,
//                 color: isOver ? Colors.orange : Colors.blue,
//               ),
//               const SizedBox(width: 6),
//               Text(
//                 isOver
//                     ? 'Too long — max ${widget.maxDurationSeconds}s'
//                     : isReady
//                     ? 'Selected: ${_fmt(_selectedSeconds)}  /  max ${widget.maxDurationSeconds}s'
//                     : 'Loading...',
//                 style: TextStyle(
//                   color: isOver ? Colors.orange : Colors.blue,
//                   fontSize: 12,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             ]),
//           ),
//         ),
//       ),
//
//       // ── Custom trim scrubber ──────────────────────────────────────────
//       if (isReady)
//         _TrimScrubber(
//           totalMs: _totalDuration.inMilliseconds.toDouble(),
//           startMs: _trimStart,
//           endMs: _trimEnd,
//           positionMs: _position.inMilliseconds.toDouble(),
//           maxDurationMs: widget.maxDurationSeconds * 1000.0,
//           onStartChanged: (v) {
//             setState(() => _trimStart = v);
//             _seekTo(v);
//           },
//           onEndChanged: (v) {
//             setState(() => _trimEnd = v);
//             _seekTo(v - 100);
//           },
//           onSeek: (v) => _seekTo(v),
//         ),
//
//       // ── Hint ──────────────────────────────────────────────────────────
//       const Padding(
//         padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
//         child: Text(
//           'Drag the yellow handles to set start and end of your clip',
//           style: TextStyle(color: Colors.white38, fontSize: 11),
//           textAlign: TextAlign.center,
//         ),
//       ),
//
//       const SizedBox(height: 8),
//
//       // ── Buttons ───────────────────────────────────────────────────────
//       Padding(
//         padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
//         child: Row(children: [
//           Expanded(
//             child: OutlinedButton(
//               onPressed: () => Navigator.pop(context, null),
//               style: OutlinedButton.styleFrom(
//                 foregroundColor: Colors.white,
//                 side: const BorderSide(color: Colors.white30),
//                 padding: const EdgeInsets.symmetric(vertical: 14),
//                 shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12)),
//               ),
//               child: const Text('Cancel'),
//             ),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             flex: 2,
//             child: ElevatedButton.icon(
//               onPressed: _trimValid ? _advanceToCrop : null,
//               icon: const Icon(Icons.crop, size: 18),
//               label: Text(
//                 isOver
//                     ? 'Too long'
//                     : !isReady
//                     ? 'Loading...'
//                     : 'Next: Crop ${_fmt(_selectedSeconds)} →',
//               ),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.blue,
//                 foregroundColor: Colors.white,
//                 disabledBackgroundColor: Colors.grey.shade800,
//                 disabledForegroundColor: Colors.white38,
//                 padding: const EdgeInsets.symmetric(vertical: 14),
//                 shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12)),
//               ),
//             ),
//           ),
//         ]),
//       ),
//     ]);
//   }
//
//   // ══════════════════════════════════════════════════════════════════════════
//   // STEP 2: CROP
//   // ══════════════════════════════════════════════════════════════════════════
//
//   Widget _buildCropStep() {
//     return Column(children: [
//       Expanded(
//         child: Stack(children: [
//           Positioned.fill(
//             child: Container(
//               key: _previewKey,
//               color: Colors.black,
//               child: _cropPreviewController != null &&
//                   _cropPreviewController!.value.isInitialized
//                   ? Center(
//                 child: AspectRatio(
//                   aspectRatio:
//                   _cropPreviewController!.value.aspectRatio,
//                   child: VideoPlayer(_cropPreviewController!),
//                 ),
//               )
//                   : const Center(
//                   child: CircularProgressIndicator(
//                       color: Colors.blue)),
//             ),
//           ),
//           Positioned.fill(
//             child: _CropOverlay(
//               cropRect: _cropRect,
//               onCropChanged: (r) {
//                 if (mounted) setState(() => _cropRect = r);
//               },
//             ),
//           ),
//           Positioned.fill(
//             child: GestureDetector(
//               behavior: HitTestBehavior.translucent,
//               onDoubleTap: () {
//                 if (_cropPreviewController == null) return;
//                 if (_cropPreviewController!.value.isPlaying) {
//                   _cropPreviewController!.pause();
//                 } else {
//                   _cropPreviewController!.play();
//                 }
//                 setState(() {});
//               },
//             ),
//           ),
//         ]),
//       ),
//       Padding(
//         padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Builder(builder: (_) {
//               final c = _cropPixels();
//               return Text('Output: ${c['w']} × ${c['h']} px',
//                   style: const TextStyle(
//                       color: Colors.white70,
//                       fontSize: 12,
//                       fontWeight: FontWeight.w500));
//             }),
//             TextButton.icon(
//               onPressed: () => setState(() =>
//               _cropRect = const Rect.fromLTWH(0.05, 0.05, 0.9, 0.9)),
//               icon: const Icon(Icons.refresh,
//                   size: 14, color: Colors.white38),
//               label: const Text('Reset',
//                   style:
//                   TextStyle(color: Colors.white38, fontSize: 12)),
//               style: TextButton.styleFrom(
//                 padding: EdgeInsets.zero,
//                 minimumSize: Size.zero,
//                 tapTargetSize: MaterialTapTargetSize.shrinkWrap,
//               ),
//             ),
//           ],
//         ),
//       ),
//       const Padding(
//         padding: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
//         child: Text(
//           'Drag box to move  •  Drag corners/edges to resize  •  Double-tap to pause',
//           style: TextStyle(color: Colors.white38, fontSize: 10),
//           textAlign: TextAlign.center,
//         ),
//       ),
//       const SizedBox(height: 12),
//       Padding(
//         padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
//         child: Row(children: [
//           Expanded(
//             child: OutlinedButton(
//               onPressed: () => Navigator.pop(context, null),
//               style: OutlinedButton.styleFrom(
//                 foregroundColor: Colors.white,
//                 side: const BorderSide(color: Colors.white30),
//                 padding: const EdgeInsets.symmetric(vertical: 14),
//                 shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12)),
//               ),
//               child: const Text('Cancel'),
//             ),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             flex: 2,
//             child: ElevatedButton.icon(
//               onPressed: _applyAndReturn,
//               icon: const Icon(Icons.check_rounded, size: 18),
//               label: const Text('Apply & Save'),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.green.shade600,
//                 foregroundColor: Colors.white,
//                 padding: const EdgeInsets.symmetric(vertical: 14),
//                 shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12)),
//               ),
//             ),
//           ),
//         ]),
//       ),
//     ]);
//   }
// }
//
// // ══════════════════════════════════════════════════════════════════════════════
// // CUSTOM TRIM SCRUBBER — replaces TrimViewer from video_trimmer package
// // Two draggable handles (yellow) on a track. No package dependency.
// // ══════════════════════════════════════════════════════════════════════════════
//
// class _TrimScrubber extends StatefulWidget {
//   final double totalMs;
//   final double startMs;
//   final double endMs;
//   final double positionMs;
//   final double maxDurationMs;
//   final ValueChanged<double> onStartChanged;
//   final ValueChanged<double> onEndChanged;
//   final ValueChanged<double> onSeek;
//
//   const _TrimScrubber({
//     required this.totalMs,
//     required this.startMs,
//     required this.endMs,
//     required this.positionMs,
//     required this.maxDurationMs,
//     required this.onStartChanged,
//     required this.onEndChanged,
//     required this.onSeek,
//   });
//
//   @override
//   State<_TrimScrubber> createState() => _TrimScrubberState();
// }
//
// class _TrimScrubberState extends State<_TrimScrubber> {
//   static const double _trackH = 52.0;
//   static const double _handleW = 20.0;
//   static const double _minGapMs = 500.0;
//
//   double _msToX(double ms, double trackW) =>
//       (ms / widget.totalMs) * trackW;
//
//   double _xToMs(double x, double trackW) =>
//       (x / trackW * widget.totalMs).clamp(0.0, widget.totalMs);
//
//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 12),
//       child: LayoutBuilder(builder: (_, box) {
//         final trackW = box.maxWidth;
//         final startX = _msToX(widget.startMs, trackW);
//         final endX = _msToX(widget.endMs, trackW);
//         final posX = _msToX(
//             widget.positionMs.clamp(widget.startMs, widget.endMs),
//             trackW);
//         final isOver =
//             widget.endMs - widget.startMs > widget.maxDurationMs;
//         final accent = isOver ? Colors.orange : Colors.yellow;
//
//         return SizedBox(
//           height: _trackH,
//           child: Stack(clipBehavior: Clip.none, children: [
//             // ── Track background ────────────────────────────────────────
//             Positioned.fill(
//               child: Container(
//                 margin: const EdgeInsets.symmetric(vertical: 8),
//                 decoration: BoxDecoration(
//                   color: Colors.white.withOpacity(0.12),
//                   borderRadius: BorderRadius.circular(4),
//                 ),
//               ),
//             ),
//
//             // ── Selected range highlight ─────────────────────────────────
//             Positioned(
//               left: startX,
//               top: 8,
//               width: (endX - startX).clamp(0.0, trackW),
//               bottom: 8,
//               child: GestureDetector(
//                 // Drag the whole selection
//                 onHorizontalDragUpdate: (d) {
//                   final delta = d.delta.dx / trackW * widget.totalMs;
//                   final dur = widget.endMs - widget.startMs;
//                   var newStart = (widget.startMs + delta)
//                       .clamp(0.0, widget.totalMs - dur);
//                   widget.onStartChanged(newStart);
//                   widget.onEndChanged(newStart + dur);
//                 },
//                 child: Container(
//                   decoration: BoxDecoration(
//                     color: accent.withOpacity(isOver ? 0.25 : 0.18),
//                     border: Border.all(
//                         color: accent.withOpacity(0.6), width: 1),
//                   ),
//                 ),
//               ),
//             ),
//
//             // ── Playhead needle ─────────────────────────────────────────
//             Positioned(
//               left: posX - 1,
//               top: 4,
//               bottom: 4,
//               child: Container(
//                 width: 2,
//                 decoration: BoxDecoration(
//                   color: Colors.white.withOpacity(0.9),
//                   borderRadius: BorderRadius.circular(1),
//                 ),
//               ),
//             ),
//
//             // ── Start handle ─────────────────────────────────────────────
//             Positioned(
//               left: startX - _handleW / 2,
//               top: 0,
//               bottom: 0,
//               child: GestureDetector(
//                 onHorizontalDragUpdate: (d) {
//                   final dx = d.delta.dx / trackW * widget.totalMs;
//                   final newStart = (widget.startMs + dx)
//                       .clamp(0.0, widget.endMs - _minGapMs);
//                   widget.onStartChanged(newStart);
//                 },
//                 child: _Handle(color: accent, isStart: true),
//               ),
//             ),
//
//             // ── End handle ───────────────────────────────────────────────
//             Positioned(
//               left: endX - _handleW / 2,
//               top: 0,
//               bottom: 0,
//               child: GestureDetector(
//                 onHorizontalDragUpdate: (d) {
//                   final dx = d.delta.dx / trackW * widget.totalMs;
//                   final newEnd = (widget.endMs + dx)
//                       .clamp(widget.startMs + _minGapMs, widget.totalMs);
//                   widget.onEndChanged(newEnd);
//                 },
//                 child: _Handle(color: accent, isStart: false),
//               ),
//             ),
//
//             // ── Time labels ─────────────────────────────────────────────
//             Positioned(
//               left: startX + _handleW / 2 + 4,
//               bottom: 0,
//               child: Text(
//                 _fmtMs(widget.startMs),
//                 style: const TextStyle(
//                     color: Colors.white70,
//                     fontSize: 9,
//                     fontWeight: FontWeight.w500),
//               ),
//             ),
//             Positioned(
//               right: trackW - endX + _handleW / 2 + 4,
//               bottom: 0,
//               child: Text(
//                 _fmtMs(widget.endMs),
//                 style: const TextStyle(
//                     color: Colors.white70,
//                     fontSize: 9,
//                     fontWeight: FontWeight.w500),
//               ),
//             ),
//           ]),
//         );
//       }),
//     );
//   }
//
//   String _fmtMs(double ms) {
//     final s = (ms / 1000).round();
//     return '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
//   }
// }
//
// class _Handle extends StatelessWidget {
//   final Color color;
//   final bool isStart;
//   const _Handle({required this.color, required this.isStart});
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: 20,
//       decoration: BoxDecoration(
//         color: color,
//         borderRadius: BorderRadius.only(
//           topLeft: Radius.circular(isStart ? 5 : 0),
//           bottomLeft: Radius.circular(isStart ? 5 : 0),
//           topRight: Radius.circular(isStart ? 0 : 5),
//           bottomRight: Radius.circular(isStart ? 0 : 5),
//         ),
//       ),
//       child: Center(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: List.generate(
//             3,
//                 (_) => Padding(
//               padding: const EdgeInsets.symmetric(vertical: 2),
//               child: Container(
//                 width: 2,
//                 height: 10,
//                 decoration: BoxDecoration(
//                   color: Colors.black.withOpacity(0.5),
//                   borderRadius: BorderRadius.circular(1),
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// // ══════════════════════════════════════════════════════════════════════════════
// // CROP OVERLAY — unchanged from original
// // ══════════════════════════════════════════════════════════════════════════════
//
// class _CropOverlay extends StatefulWidget {
//   final Rect cropRect;
//   final ValueChanged<Rect> onCropChanged;
//   const _CropOverlay(
//       {required this.cropRect, required this.onCropChanged});
//
//   @override
//   State<_CropOverlay> createState() => _CropOverlayState();
// }
//
// class _CropOverlayState extends State<_CropOverlay> {
//   static const double _h = 28.0;
//   static const double _min = 0.08;
//   late Rect _rect;
//
//   @override
//   void initState() {
//     super.initState();
//     _rect = widget.cropRect;
//   }
//
//   @override
//   void didUpdateWidget(_CropOverlay old) {
//     super.didUpdateWidget(old);
//     if (old.cropRect != widget.cropRect) _rect = widget.cropRect;
//   }
//
//   Rect _px(Size s) => Rect.fromLTRB(
//     _rect.left * s.width,
//     _rect.top * s.height,
//     _rect.right * s.width,
//     _rect.bottom * s.height,
//   );
//
//   void _emit() => widget.onCropChanged(_rect);
//
//   @override
//   Widget build(BuildContext context) {
//     return LayoutBuilder(builder: (_, constraints) {
//       final size = Size(constraints.maxWidth, constraints.maxHeight);
//       final px = _px(size);
//       return Stack(children: [
//         CustomPaint(size: size, painter: _DimPainter(cropRect: px)),
//         Positioned(
//           left: px.left + _h / 2,
//           top: px.top + _h / 2,
//           width: math.max(px.width - _h, 0),
//           height: math.max(px.height - _h, 0),
//           child: GestureDetector(
//             onPanUpdate: (d) {
//               final dx = d.delta.dx / size.width;
//               final dy = d.delta.dy / size.height;
//               setState(() {
//                 final l = (_rect.left + dx)
//                     .clamp(0.0, 1.0 - _rect.width);
//                 final t = (_rect.top + dy)
//                     .clamp(0.0, 1.0 - _rect.height);
//                 _rect = Rect.fromLTWH(l, t, _rect.width, _rect.height);
//               });
//               _emit();
//             },
//             child: Container(color: Colors.transparent),
//           ),
//         ),
//         Positioned(
//           left: px.left,
//           top: px.top,
//           width: px.width,
//           height: px.height,
//           child: IgnorePointer(
//             child: CustomPaint(
//               painter: _BorderGridPainter(
//                   rect:
//                   Rect.fromLTWH(0, 0, px.width, px.height)),
//             ),
//           ),
//         ),
//         _corner(size, _Corner.topLeft,
//             left: px.left - _h / 2,
//             top: px.top - _h / 2,
//             onDrag: (d) {
//               final dx = d.delta.dx / size.width,
//                   dy = d.delta.dy / size.height;
//               setState(() {
//                 final l = (_rect.left + dx)
//                     .clamp(0.0, _rect.right - _min);
//                 final t = (_rect.top + dy)
//                     .clamp(0.0, _rect.bottom - _min);
//                 _rect =
//                     Rect.fromLTRB(l, t, _rect.right, _rect.bottom);
//               });
//               _emit();
//             }),
//         _corner(size, _Corner.topRight,
//             left: px.right - _h / 2,
//             top: px.top - _h / 2,
//             onDrag: (d) {
//               final dx = d.delta.dx / size.width,
//                   dy = d.delta.dy / size.height;
//               setState(() {
//                 final r = (_rect.right + dx)
//                     .clamp(_rect.left + _min, 1.0);
//                 final t = (_rect.top + dy)
//                     .clamp(0.0, _rect.bottom - _min);
//                 _rect = Rect.fromLTRB(
//                     _rect.left, t, r, _rect.bottom);
//               });
//               _emit();
//             }),
//         _corner(size, _Corner.bottomLeft,
//             left: px.left - _h / 2,
//             top: px.bottom - _h / 2,
//             onDrag: (d) {
//               final dx = d.delta.dx / size.width,
//                   dy = d.delta.dy / size.height;
//               setState(() {
//                 final l = (_rect.left + dx)
//                     .clamp(0.0, _rect.right - _min);
//                 final b = (_rect.bottom + dy)
//                     .clamp(_rect.top + _min, 1.0);
//                 _rect =
//                     Rect.fromLTRB(l, _rect.top, _rect.right, b);
//               });
//               _emit();
//             }),
//         _corner(size, _Corner.bottomRight,
//             left: px.right - _h / 2,
//             top: px.bottom - _h / 2,
//             onDrag: (d) {
//               final dx = d.delta.dx / size.width,
//                   dy = d.delta.dy / size.height;
//               setState(() {
//                 final r = (_rect.right + dx)
//                     .clamp(_rect.left + _min, 1.0);
//                 final b = (_rect.bottom + dy)
//                     .clamp(_rect.top + _min, 1.0);
//                 _rect =
//                     Rect.fromLTRB(_rect.left, _rect.top, r, b);
//               });
//               _emit();
//             }),
//         _edge(
//             left: px.left + px.width / 2 - _h / 2,
//             top: px.top - _h / 2,
//             horizontal: true,
//             onDrag: (d) {
//               final dy = d.delta.dy / size.height;
//               setState(() {
//                 final t = (_rect.top + dy)
//                     .clamp(0.0, _rect.bottom - _min);
//                 _rect = Rect.fromLTRB(
//                     _rect.left, t, _rect.right, _rect.bottom);
//               });
//               _emit();
//             }),
//         _edge(
//             left: px.left + px.width / 2 - _h / 2,
//             top: px.bottom - _h / 2,
//             horizontal: true,
//             onDrag: (d) {
//               final dy = d.delta.dy / size.height;
//               setState(() {
//                 final b = (_rect.bottom + dy)
//                     .clamp(_rect.top + _min, 1.0);
//                 _rect = Rect.fromLTRB(
//                     _rect.left, _rect.top, _rect.right, b);
//               });
//               _emit();
//             }),
//         _edge(
//             left: px.left - _h / 2,
//             top: px.top + px.height / 2 - _h / 2,
//             horizontal: false,
//             onDrag: (d) {
//               final dx = d.delta.dx / size.width;
//               setState(() {
//                 final l = (_rect.left + dx)
//                     .clamp(0.0, _rect.right - _min);
//                 _rect = Rect.fromLTRB(
//                     l, _rect.top, _rect.right, _rect.bottom);
//               });
//               _emit();
//             }),
//         _edge(
//             left: px.right - _h / 2,
//             top: px.top + px.height / 2 - _h / 2,
//             horizontal: false,
//             onDrag: (d) {
//               final dx = d.delta.dx / size.width;
//               setState(() {
//                 final r = (_rect.right + dx)
//                     .clamp(_rect.left + _min, 1.0);
//                 _rect = Rect.fromLTRB(
//                     _rect.left, _rect.top, r, _rect.bottom);
//               });
//               _emit();
//             }),
//       ]);
//     });
//   }
//
//   Widget _corner(Size size, _Corner c,
//       {required double left,
//         required double top,
//         required void Function(DragUpdateDetails) onDrag}) {
//     return Positioned(
//       left: left,
//       top: top,
//       child: GestureDetector(
//         onPanUpdate: onDrag,
//         child: SizedBox(
//           width: _h,
//           height: _h,
//           child: CustomPaint(painter: _CornerPainter(corner: c)),
//         ),
//       ),
//     );
//   }
//
//   Widget _edge(
//       {required double left,
//         required double top,
//         required bool horizontal,
//         required void Function(DragUpdateDetails) onDrag}) {
//     return Positioned(
//       left: left,
//       top: top,
//       child: GestureDetector(
//         onPanUpdate: onDrag,
//         child: SizedBox(
//           width: _h,
//           height: _h,
//           child: Center(
//             child: Container(
//               width: horizontal ? 24 : 4,
//               height: horizontal ? 4 : 24,
//               decoration: BoxDecoration(
//                 color: Colors.white.withOpacity(0.85),
//                 borderRadius: BorderRadius.circular(2),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
//
//
//
// // ── Painters ──────────────────────────────────────────────────────────────────
//
// enum _Corner { topLeft, topRight, bottomLeft, bottomRight }
//
// class _DimPainter extends CustomPainter {
//   final Rect cropRect;
//   _DimPainter({required this.cropRect});
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     final path = Path()
//       ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
//       ..addRect(cropRect)
//       ..fillType = PathFillType.evenOdd;
//     canvas.drawPath(path, Paint()..color = Colors.black.withOpacity(0.55));
//   }
//
//   @override
//   bool shouldRepaint(_DimPainter old) => old.cropRect != cropRect;
// }
//
// class _BorderGridPainter extends CustomPainter {
//   final Rect rect;
//   _BorderGridPainter({required this.rect});
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     final border = Paint()
//       ..color = Colors.white
//       ..strokeWidth = 1.5
//       ..style = PaintingStyle.stroke;
//     canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), border);
//
//     final grid = Paint()
//       ..color = Colors.white.withOpacity(0.25)
//       ..strokeWidth = 0.8;
//     canvas.drawLine(Offset(size.width / 3, 0), Offset(size.width / 3, size.height), grid);
//     canvas.drawLine(Offset(size.width * 2 / 3, 0), Offset(size.width * 2 / 3, size.height), grid);
//     canvas.drawLine(Offset(0, size.height / 3), Offset(size.width, size.height / 3), grid);
//     canvas.drawLine(Offset(0, size.height * 2 / 3), Offset(size.width, size.height * 2 / 3), grid);
//   }
//
//   @override
//   bool shouldRepaint(_BorderGridPainter old) => old.rect != rect;
// }
//
// class _CornerPainter extends CustomPainter {
//   final _Corner corner;
//   _CornerPainter({required this.corner});
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()
//       ..color = Colors.white
//       ..strokeWidth = 3
//       ..strokeCap = StrokeCap.round
//       ..style = PaintingStyle.stroke;
//
//     final arm = math.min(size.width, size.height) * 0.55;
//     late Offset pt, a, b;
//     switch (corner) {
//       case _Corner.topLeft:
//         pt = Offset.zero; a = Offset(arm, 0); b = Offset(0, arm); break;
//       case _Corner.topRight:
//         pt = Offset(size.width, 0); a = Offset(size.width - arm, 0); b = Offset(size.width, arm); break;
//       case _Corner.bottomLeft:
//         pt = Offset(0, size.height); a = Offset(arm, size.height); b = Offset(0, size.height - arm); break;
//       case _Corner.bottomRight:
//         pt = Offset(size.width, size.height); a = Offset(size.width - arm, size.height); b = Offset(size.width, size.height - arm); break;
//     }
//     canvas.drawPath(Path()..moveTo(a.dx, a.dy)..lineTo(pt.dx, pt.dy)..lineTo(b.dx, b.dy), paint);
//   }
//
//   @override
//   bool shouldRepaint(_CornerPainter old) => old.corner != corner;
// }