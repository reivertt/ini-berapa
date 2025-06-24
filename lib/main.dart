import 'package:flutter/material.dart';
import 'package:ini_berapa/screens/splash_screen_no_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null); 

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ini Berapa',
      // --- PERUBAHAN TEMA DI SINI ---
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.deepPurple, // Warna utama menjadi ungu
        scaffoldBackgroundColor: const Color(0xFF121212), // Latar belakang abu-abu gelap
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.deepPurple, // Warna AppBar
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurpleAccent, // Warna tombol
            foregroundColor: Colors.white,
          ),
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: Colors.deepPurpleAccent,
        ),
      ),
      // --- AKHIR PERUBAHAN TEMA ---
      debugShowCheckedModeBanner: false,
      home: const SplashScreenNoFonts(),
    );
  }
}