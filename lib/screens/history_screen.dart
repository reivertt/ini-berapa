import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:ini_berapa/models/detection_history.dart';
import 'package:ini_berapa/utils/database_helper.dart';
import 'package:ini_berapa/utils/currency_parser.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late FlutterTts _flutterTts;
  late Future<Map<String, List<DetectionHistory>>> _groupedHistory;
  
  // Formatter untuk menampilkan mata uang format Rupiah
  final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _flutterTts = FlutterTts();
    _groupedHistory = _loadAndGroupHistory();
  }

  Future<Map<String, List<DetectionHistory>>> _loadAndGroupHistory() async {
    final historyList = await DatabaseHelper.instance.getAllHistory();

    // --- TAMBAHAN UNTUK DEBUGGING ---
    debugPrint("DATABASE: Mengambil data, jumlah item: ${historyList.length}");
    // --------------------------------

    final Map<String, List<DetectionHistory>> grouped = {};
    
    for (var history in historyList) {
      // Menggunakan intl untuk memformat tanggal ke format Indonesia
      final dateKey = DateFormat('d MMMM yyyy', 'id_ID').format(history.timestamp);
      if (grouped[dateKey] == null) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(history);
    }
    
    // Setelah data dikelompokkan, siapkan ringkasan suara
    _speakSummary(grouped);

    return grouped;
  }

  void _speakSummary(Map<String, List<DetectionHistory>> groupedData) async {
    if (!mounted) return;

    if (groupedData.isEmpty) {
      _speak("Riwayat deteksi masih kosong.");
      return;
    }

    String summarySpeech = "Berikut adalah ringkasan riwayat deteksi Anda. ";
    groupedData.forEach((date, histories) {
      int dailyTotal = 0;
      for (var history in histories) {
        dailyTotal += parseCurrencyValue(history.label);
      }
      summarySpeech += "Pada tanggal $date, total uang yang terdeteksi adalah ${currencyFormatter.format(dailyTotal)}. ";
    });
    
    await _flutterTts.setLanguage("id-ID");
    await _flutterTts.setSpeechRate(0.5);
    _speak(summarySpeech);
  }
  
  Future<void> _speak(String text) async {
    await _flutterTts.stop();
    await _flutterTts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Riwayat Deteksi"),
      ),
      body: FutureBuilder<Map<String, List<DetectionHistory>>>(
        future: _groupedHistory,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error memuat riwayat: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
                child: Text(
                  "Tidak ada riwayat deteksi.",
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
            );
          }

          final groupedData = snapshot.data!;
          final dateKeys = groupedData.keys.toList();

          return ListView.builder(
            itemCount: dateKeys.length,
            itemBuilder: (context, index) {
              final date = dateKeys[index];
              final histories = groupedData[date]!;
              
              int dailyTotal = 0;
              for (var history in histories) {
                dailyTotal += parseCurrencyValue(history.label);
              }
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Tanggal dan Total
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                    child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                         Text(
                          date,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                         Text(
                          "Total hari ini: ${currencyFormatter.format(dailyTotal)}",
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey.shade400),
                        ),
                      ],
                    ),
                  ),
                  const Divider(indent: 16, endIndent: 16),
                  // Daftar Card untuk setiap deteksi
                  ...histories.map((history) => _buildHistoryCard(history)).toList(),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHistoryCard(DetectionHistory history) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Image.file(
                File(history.imagePath),
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                // Menambahkan error builder jika gambar tidak ditemukan
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey.shade800,
                    child: const Icon(Icons.broken_image, color: Colors.grey, size: 40),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    history.label,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    // Format waktu menjadi Jam:Menit
                    DateFormat('HH:mm', 'id_ID').format(history.timestamp),
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}