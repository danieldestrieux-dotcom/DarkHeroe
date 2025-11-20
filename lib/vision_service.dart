import 'dart:async';
import 'package:camera/camera.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'dart:ui' show Size;

class VisionService {
  CameraController? _controller;
  ObjectDetector? _detector;
  final StreamController<List<DetectedObject>> _objects = StreamController.broadcast();
  Stream<List<DetectedObject>> get stream => _objects.stream;
  CameraController? get controller => _controller;
  bool _processing = false;
  DateTime _lastProcessed = DateTime.fromMillisecondsSinceEpoch(0);
  final Duration _minInterval = const Duration(milliseconds: 120);

  Future<void> init() async {
    if (_controller != null) return;
    final cameras = await availableCameras();
    final cam = cameras.first;
    _controller = CameraController(cam, ResolutionPreset.medium, enableAudio: false);
    await _controller!.initialize();
    final options = ObjectDetectorOptions(classifyObjects: true, multipleObjects: true, mode: DetectionMode.stream);
    _detector = ObjectDetector(options: options);
    _controller!.startImageStream((img) async {
      if (_processing) return;
      final now = DateTime.now();
      if (now.difference(_lastProcessed) < _minInterval) return;
      _lastProcessed = now;
      _processing = true;
      try {
        final input = InputImage.fromBytes(
          bytes: img.planes.first.bytes,
          metadata: InputImageMetadata(
            size: Size(img.width.toDouble(), img.height.toDouble()),
            rotation: InputImageRotation.rotation0deg,
            format: InputImageFormat.nv21,
            bytesPerRow: img.planes.first.bytesPerRow,
          ),
        );
        final res = await _detector!.processImage(input);
        _objects.add(res);
      } finally {
        _processing = false;
      }
    });
  }

  Future<void> dispose() async {
    try {
      await _controller?.stopImageStream();
    } catch (_) {}
    await _controller?.dispose();
    await _detector?.close();
    await _objects.close();
    _controller = null;
    _detector = null;
  }

  Future<String?> capturePhoto() async {
    if (_controller == null) return null;
    bool wasStreaming = false;
    try {
      wasStreaming = _controller!.value.isStreamingImages;
    } catch (_) {}
    try {
      if (wasStreaming) {
        try { await _controller!.stopImageStream(); } catch (_) {}
      }
      final x = await _controller!.takePicture();
      final p = x.path;
      if (wasStreaming) {
        try { await _controller!.startImageStream((_) {}); } catch (_) {}
      }
      return p;
    } catch (_) {
      return null;
    }
  }
}
