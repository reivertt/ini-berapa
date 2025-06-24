import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ini_berapa/screens/result_screen.dart';
import 'package:ini_berapa/screens/settings_screen.dart';
import 'package:ini_berapa/screens/history_screen.dart';
import 'package:ini_berapa/widgets/feedback_widget.dart';
import 'package:ini_berapa/models/feedback.dart' as app_feedback;
import 'package:ini_berapa/utils/feedback_database.dart';

class CameraScreenWithFeedback extends StatefulWidget {
  const CameraScreenWithFeedback({super.key});

  @override
  State<CameraScreenWithFeedback> createState() => _CameraScreenWithFeedbackState();
}

class _CameraScreenWithFeedbackState extends State<CameraScreenWithFeedback> {
  late FlutterTts _flutterTts;
  List<CameraDescription>? _cameras;
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;

  // Feedback related variables
  bool _showFeedback = false;
  String? _currentDetectedValue;
  String? _capturedImagePath;
  // String? _lastDetectedValue; // To track changes

  // Settings variables
  double _confidenceThreshold = 0.4;
  double _iouThreshold = 0.1;
  bool _agnosticNMS = false;

  @override
  void initState() {
    super.initState();
    _initializeAll();
  }
  
  Future<void> _initializeAll() async {
    _flutterTts = FlutterTts();
    await _flutterTts.setLanguage("id-ID");
    await _flutterTts.setSpeechRate(0.5);
    await _initializeCamera();
    Future.delayed(const Duration(milliseconds: 500), () {
      _speakCameraInstructions();
    });
  }

  Future<void> _initializeCamera() async {
    await Permission.camera.request();
    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
      _cameraController = CameraController(
        _cameras![0],
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await _cameraController!.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    }
  }

  Future<void> _speak(String text) async {
    await _flutterTts.stop();
    await _flutterTts.speak(text);
  }

  void _speakCameraInstructions() {
    const String instructions = "Kamera aktif. Arahkan ponsel ke uang kertas. "
        "Untuk mengambil gambar, sentuh area besar di bagian bawah layar. "
        "Tombol riwayat ada di kiri atas. "
        "Tombol pengaturan ada di kanan atas.";
    _speak(instructions);
  }

  void _showFeedbackPrompt(String detectedValue, String imagePath) {
    setState(() {
      _currentDetectedValue = detectedValue;
      _capturedImagePath = imagePath;
      _showFeedback = true;
    });
    _speak("Apakah hasil deteksi $detectedValue sudah benar?");
  }


  // // Simulate banknote detection (replace with your actual detection logic)
  // void _simulateBanknoteDetection(String detectedValue) {
  //   // Check if this is a different banknote than the last one
  //   if (_lastDetectedValue != detectedValue) {
  //     setState(() {
  //       _currentDetectedValue = detectedValue;
  //       _lastDetectedValue = detectedValue;
  //       _showFeedback = true;
  //     });
  //   }
  // }

  void _handleFeedback(bool isCorrect, String? actualValue) {
    // Save the feedback to the database
    _saveFeedbackToDatabase(isCorrect, actualValue);

    // Give verbal confirmation and hide the feedback widget
    if (isCorrect) {
      _speak("Terima kasih atas konfirmasinya.");
    } else {
      _speak("Terima kasih atas masukannya. Data telah diperbarui.");
    }
    _dismissFeedback();
  }

  Future<void> _saveFeedbackToDatabase(bool isCorrect, String? actualValue) async {
    if (_currentDetectedValue == null) return;

    // Use the prefix to specify YOUR Feedback class
    final feedbackData = app_feedback.Feedback( // <-- This line is now fixed
      timestamp: DateTime.now(),
      detectedValue: _currentDetectedValue!,
      isCorrect: isCorrect,
      actualValue: actualValue,
      imagePath: _capturedImagePath,
    );

    await FeedbackDatabase.insertFeedback(feedbackData);

    debugPrint("FEEDBACK SAVED: {Detected: ${feedbackData.detectedValue}, Correct: ${feedbackData.isCorrect}, Actual: ${feedbackData.actualValue}}");
  }

  void _dismissFeedback() {
    setState(() {
      _showFeedback = false;
      _currentDetectedValue = null;
      _capturedImagePath = null;
    });
  }

  Future<void> _captureImage() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized || _isProcessing) {
      return;
    }

    setState(() { _isProcessing = true; });

    try {
      _speak("Mengambil gambar...");
      final XFile imageFile = await _cameraController!.takePicture();

      if (!mounted) return;
      
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultScreen(
            imagePath: imageFile.path,
            confidenceThreshold: _confidenceThreshold,
            iouThreshold: _iouThreshold,
            agnosticNMS: _agnosticNMS,
          ),
        ),
      );

      // If a banknote was detected, show feedback
      if (result is Map && result.containsKey('detected_label')) {
        _showFeedbackPrompt(result['detected_label'], result['image_path']);
      } else {
        // If no detection or user just comes back, give instructions again.
        _speakCameraInstructions();
      }
    } catch (e) {
      debugPrint('Error taking picture: $e');
      _speak("Gagal mengambil gambar. Silakan coba lagi.");
    } finally {
      if(mounted) {
        setState(() { _isProcessing = false; });
      }
    }
  }

  void _navigateToSettings() async {
    final newSettings = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsScreen(
          initialConfidence: _confidenceThreshold,
          initialIoU: _iouThreshold,
          initialAgnosticNMS: _agnosticNMS,
        ),
      ),
    );

    if (newSettings != null && mounted) {
      setState(() {
        _confidenceThreshold = newSettings['confidence'];
        _iouThreshold = newSettings['iou'];
        _agnosticNMS = newSettings['agnosticNMS'];
      });
      _speak("Pengaturan telah diperbarui.");
    }
  }
  
  void _navigateToHistory() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryScreen()));
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    double scale = 1.0;
    if (_isCameraInitialized) {
      scale = 1 / (_cameraController!.value.aspectRatio * size.aspectRatio);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Arahkan Kamera"),
        leading: IconButton(
          icon: const Icon(Icons.history),
          tooltip: "Buka Riwayat Deteksi",
          onPressed: _navigateToHistory,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: "Buka Pengaturan",
            onPressed: _navigateToSettings,
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          !_isCameraInitialized
              ? const Center(child: CircularProgressIndicator())
              : Center(
            child: Transform.scale(
              scale: scale,
              child: CameraPreview(_cameraController!),
            ),
          ),

          // Capture button area
          Positioned(
            bottom: _showFeedback ? 200 : 0, // Adjust position when feedback is shown
            left: 0,
            right: 0,
            child: GestureDetector(
              onTap: _captureImage,
              child: Semantics(
                label: "Area Tombol Ambil Gambar",
                button: true,
                child: Container(
                  height: 120,
                  color: Colors.black.withOpacity(0.5),
                  child: Center(
                    child: _isProcessing
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Icon(
                      Icons.camera,
                      color: Colors.white,
                      size: 60,
                      semanticLabel: "Ambil Gambar",
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Feedback widget at the bottom
          if (_showFeedback && _currentDetectedValue != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: FeedbackWidget(
                detectedValue: _currentDetectedValue!,
                onFeedback: _handleFeedback,
                onDismiss: _dismissFeedback,
              ),
            ),
        ],
      ),
    );
  }
}
