import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:image/image.dart' as img;
import 'dart:math';
import 'package:ini_berapa/models/detection_history.dart';
import 'package:ini_berapa/utils/database_helper.dart';
import 'package:ini_berapa/utils/yolo.dart';
import 'package:ini_berapa/utils/labels.dart';
import 'package:ini_berapa/utils/bbox.dart';
import 'package:ini_berapa/widgets/feedback_widget.dart';
import 'package:ini_berapa/models/feedback.dart' as app_feedback;
import 'package:ini_berapa/utils/feedback_database.dart';

class ResultWithFeedbackScreen extends StatefulWidget {
  final String imagePath;
  final double confidenceThreshold;
  final double iouThreshold;
  final bool agnosticNMS;

  const ResultWithFeedbackScreen({
    super.key,
    required this.imagePath,
    required this.confidenceThreshold,
    required this.iouThreshold,
    required this.agnosticNMS,
  });

  @override
  State<ResultWithFeedbackScreen> createState() => _ResultWithFeedbackScreenState();
}

class _ResultWithFeedbackScreenState extends State<ResultWithFeedbackScreen> {
  // --- STATE FROM result_screen.dart ---
  late FlutterTts _flutterTts;
  YoloModel? _yoloModel;
  bool _isLoading = true;
  String _detectionResultText = "";
  List<Widget> _boundingBoxes = [];
  File? _imageFile;
  String? _bestDetectedLabel;

  // --- STATE FROM camera_screen_with_feedback.dart ---
  bool _showFeedback = false;
  // Note: _currentDetectedValue is replaced by _bestDetectedLabel
  String? _capturedImagePath;

  @override
  void initState() {
    super.initState();
    _imageFile = File(widget.imagePath);
    _capturedImagePath = widget.imagePath; // Store image path for feedback
    _initializeAndProcess();
  }

  Future<void> _initializeAndProcess() async {
    _flutterTts = FlutterTts();
    await _flutterTts.setLanguage("id-ID");
    await _flutterTts.setSpeechRate(0.5);
    _speak("Menganalisis gambar...");

    _yoloModel = YoloModel('assets/models/yolov8n.tflite', 800, 800, 10);
    await _yoloModel!.init();

    await _detectObjectInImage();
  }

  Future<void> _detectObjectInImage() async {
    final imageBytes = await _imageFile!.readAsBytes();
    final img.Image? originalImage = img.decodeImage(imageBytes);

    if (originalImage != null && _yoloModel != null) {
      final (classes, bboxes, scores) = _yoloModel!.postprocess(
        _yoloModel!.infer(originalImage),
        originalImage.width,
        originalImage.height,
        confidenceThreshold: widget.confidenceThreshold,
        iouThreshold: widget.iouThreshold,
        agnostic: widget.agnosticNMS,
      );

      String resultText = "Tidak ada uang yang terdeteksi";
      bool shouldShowFeedback = false; // Local flag to control the flow

      if (scores.isNotEmpty) {
        double maxScore = 0;
        int bestIndex = -1;
        for (int i = 0; i < scores.length; i++) {
          if (scores[i] > maxScore) {
            maxScore = scores[i];
            bestIndex = i;
          }
        }
        if (bestIndex != -1) {
          _bestDetectedLabel = labels[classes[bestIndex]];
          resultText = "Hasil deteksi: $_bestDetectedLabel";

          final history = DetectionHistory(
            label: _bestDetectedLabel!,
            imagePath: widget.imagePath,
            timestamp: DateTime.now(),
          );
          await DatabaseHelper.instance.insertHistory(history);

          // Set the flag to true instead of calling a separate function
          shouldShowFeedback = true;
        }
      }

      // --- SINGLE SETSTATE CALL ---
      // All state changes are now consolidated here
      if (mounted) {
        setState(() {
          _detectionResultText = resultText;
          _boundingBoxes = _buildBoundingBoxes(originalImage, classes, bboxes, scores);
          _isLoading = false;
          // Set _showFeedback within the same setState call
          if (shouldShowFeedback) {
            _showFeedback = true;
          }
        });
      }

      // Handle speaking logic after the state is set
      if (shouldShowFeedback) {
        _speak("Apakah hasil deteksi $_bestDetectedLabel sudah benar?");
      } else {
        _speak("$resultText. Tekan tombol Ambil Gambar Lagi untuk kembali.");
      }
    }
  }


  List<Widget> _buildBoundingBoxes(img.Image image, List<int> classes, List<List<double>> bboxes, List<double> scores) {
    final bboxesColors = List<Color>.generate(
      labels.length,
          (_) => Color((Random().nextDouble() * 0xFFFFFF).toInt()).withAlpha(255),
    );
    final double displayWidth = MediaQuery.of(context).size.width;
    double k = displayWidth / image.width;
    List<Widget> widgets = [];
    for (int i = 0; i < bboxes.length; i++) {
      widgets.add(Bbox(
        bboxes[i][0] * k,
        bboxes[i][1] * k,
        bboxes[i][2] * k,
        bboxes[i][3] * k,
        labels[classes[i]],
        scores[i],
        bboxesColors[classes[i] % bboxesColors.length],
      ));
    }
    return widgets;
  }

  Future<void> _speak(String text) async {
    await _flutterTts.stop();
    await _flutterTts.speak(text);
  }

  void _handleFeedback(bool isCorrect, String? actualValue) {
    _saveFeedbackToDatabase(isCorrect, actualValue);
    if (isCorrect) {
      _speak("Terima kasih atas konfirmasinya.");
    } else {
      _speak("Terima kasih atas masukannya. Data telah diperbarui.");
    }
    _dismissFeedback();
  }

  Future<void> _saveFeedbackToDatabase(bool isCorrect, String? actualValue) async {
    // --- FIX #1: Use the correct variable here ---
    if (_bestDetectedLabel == null) return;

    // Use the prefix to specify YOUR Feedback class
    final feedbackData = app_feedback.Feedback(
      timestamp: DateTime.now(),
      // --- FIX #2: And use the correct variable here ---
      detectedValue: _bestDetectedLabel!,
      isCorrect: isCorrect,
      actualValue: actualValue,
      imagePath: _capturedImagePath,
    );

    await FeedbackDatabase.insertFeedback(feedbackData);

    // The debug print can also be updated to be consistent
    debugPrint("FEEDBACK SAVED: {Detected: ${feedbackData.detectedValue}, Correct: ${feedbackData.isCorrect}, Actual: ${feedbackData.actualValue}}");
  }

  void _dismissFeedback() {
    setState(() {
      _showFeedback = false;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Hasil Deteksi"),
        // The back button now simply pops the screen without data
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: "Kembali ke kamera",
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        fit: StackFit.expand,
        children: [
          // Main content column
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                child: FittedBox(
                  child: SizedBox(
                    width: _boundingBoxes.isEmpty ? MediaQuery.of(context).size.width : null,
                    child: Stack(
                      children: [
                        Image.file(_imageFile!),
                        ..._boundingBoxes,
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Container(
                  color: Colors.black87,
                  child: Center(
                    child: Text(
                      _detectionResultText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              // Add padding at the bottom to make space for the feedback widget
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: _showFeedback ? 210 : 90,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16,16,16,16),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.camera_alt),
                    label: const Text("Ambil Gambar Lagi", style: TextStyle(fontSize: 18)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
              ),
            ],
          ),

          // --- FEEDBACK WIDGET ---
          // Conditionally display the feedback widget at the bottom
          if (_showFeedback && _bestDetectedLabel != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: FeedbackWidget(
                detectedValue: _bestDetectedLabel!,
                onFeedback: _handleFeedback,
                onDismiss: _dismissFeedback,
              ),
            ),
        ],
      ),
    );
  }
}