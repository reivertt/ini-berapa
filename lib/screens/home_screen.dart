import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:ini_berapa/screens/camera_screen.dart';
// import 'camera_screen_with_feedback.dart';
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late FlutterTts _flutterTts;

  @override
  void initState() {
    super.initState();
    _initializeTtsAndSpeak();
  }

  void _initializeTtsAndSpeak() async {
    _flutterTts = FlutterTts();
    await _flutterTts.setLanguage("id-ID");
    await _flutterTts.setSpeechRate(0.5);
    Future.delayed(const Duration(milliseconds: 500), () {
      _speak("Selamat datang di aplikasi Ini Berapa. Silakan ketuk di mana saja pada layar untuk memulai kamera.");
    });
  }
  
  Future<void> _speak(String text) async {
    await _flutterTts.stop();
    await _flutterTts.speak(text);
  }

  void _navigateToCamera() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CameraScreen()),
      // MaterialPageRoute(builder: (context) => const CameraScreenWithFeedback()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: _navigateToCamera,
        child: Container(
          // --- PERUBAHAN DARI WARNA HITAM MENJADI GRADASI UNGU ---
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.deepPurple.shade900,
                Colors.deepPurple.shade600,
                Colors.deepPurple.shade800,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          // --- AKHIR PERUBAHAN ---
          width: double.infinity,
          height: double.infinity,
          child: const Center(
            child: Text(
              "Ini Berapa?",
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    blurRadius: 10.0,
                    color: Colors.black45,
                    offset: Offset(2.0, 2.0),
                  ),
                ],
              ),
              semanticsLabel: "Judul Aplikasi, Ini Berapa?",
            ),
          ),
        ),
      ),
    );
  }
}