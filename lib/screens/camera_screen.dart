import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ini_berapa/screens/result_screen.dart';
import 'package:ini_berapa/screens/settings_screen.dart';
import 'package:ini_berapa/screens/history_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late FlutterTts _flutterTts;
  List<CameraDescription>? _cameras;
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isProcessing = false; // Mencegah double-tap saat memproses

  // Variabel untuk menampung nilai settings
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
    // Beri jeda sedikit agar UI siap
    Future.delayed(const Duration(milliseconds: 500), () {
      _speakCameraInstructions(); // Panggil instruksi lengkap
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

  // --- FUNGSI BARU UNTUK INSTRUKSI SUARA YANG BISA DIPANGGIL ULANG ---
  void _speakCameraInstructions() {
    const String instructions = "Kamera aktif. Arahkan ponsel ke uang kertas. "
        "Untuk mengambil gambar, sentuh area besar di bagian bawah layar. "
        "Tombol riwayat ada di kiri atas. "
        "Tombol pengaturan ada di kanan atas.";
    _speak(instructions);
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
      // Tunggu hasil dari halaman result
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
      // --- PERUBAHAN DI SINI: Ucapkan instruksi lagi saat kembali ---
      if(result != null && result == true && mounted) {
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
              : CameraPreview(_cameraController!),

          // --- PERUBAHAN DI SINI: AREA TOMBOL LEBIH BESAR ---
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: GestureDetector(
              onTap: _captureImage,
              child: Semantics(
                label: "Area Tombol Ambil Gambar",
                button: true, // Memberitahu screen reader ini adalah tombol
                child: Container(
                  height: 120, // Area vertikal yang cukup besar
                  color: Colors.black.withOpacity(0.5), // Latar belakang semi-transparan
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
          )
        ],
      ),
    );
  }
}