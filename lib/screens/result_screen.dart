import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:image/image.dart' as img;
import 'package:ini_berapa/models/detection_history.dart';
import 'package:ini_berapa/utils/database_helper.dart';
import 'package:ini_berapa/utils/yolo.dart'; 
import 'package:ini_berapa/utils/labels.dart';
import 'package:ini_berapa/utils/bbox.dart';
import 'dart:math';

class ResultScreen extends StatefulWidget {
  final String imagePath;
  final double confidenceThreshold;
  final double iouThreshold;
  final bool agnosticNMS;

  const ResultScreen({
    super.key,
    required this.imagePath,
    required this.confidenceThreshold,
    required this.iouThreshold,
    required this.agnosticNMS,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late FlutterTts _flutterTts;
  YoloModel? _yoloModel;
  
  bool _isLoading = true;
  String _detectionResultText = "";
  List<Widget> _boundingBoxes = [];
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    _imageFile = File(widget.imagePath);
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
          final String bestLabel = labels[classes[bestIndex]];
          resultText = "Hasil deteksi: $bestLabel";

          // --- LOGIKA PENYIMPANAN YANG DIPASTIKAN ---
          final history = DetectionHistory(
            label: bestLabel,
            imagePath: widget.imagePath,
            timestamp: DateTime.now(),
          );
          try {
            await DatabaseHelper.instance.insertHistory(history);
            debugPrint("SUKSES: Riwayat untuk '$bestLabel' telah disimpan ke database.");
          } catch (e) {
            debugPrint("ERROR SAAT MENYIMPAN: $e");
          }
          // --- AKHIR LOGIKA PENYIMPANAN ---
        }
      }
      
      if (mounted) {
        setState(() {
          _detectionResultText = resultText;
          _boundingBoxes = _buildBoundingBoxes(originalImage, classes, bboxes, scores);
          _isLoading = false;
        });
      }
      
      final String finalSpeech = "$resultText. Tekan tombol Ambil Gambar Lagi di bagian bawah layar untuk kembali ke kamera.";
      await _speak(finalSpeech);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Hasil Deteksi"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: "Kembali ke kamera",
          onPressed: () => Navigator.pop(context, true),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text("Menganalisis gambar...", style: TextStyle(fontSize: 16)),
                ],
              ),
            )
          : Column(
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
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.camera_alt),
                    label: const Text("Ambil Gambar Lagi", style: TextStyle(fontSize: 18)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () {
                      Navigator.pop(context, true);
                    },
                  ),
                )
              ],
            ),
    );
  }
}