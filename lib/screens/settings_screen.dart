import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  final double initialConfidence;
  final double initialIoU;
  final bool initialAgnosticNMS;

  const SettingsScreen({
    super.key,
    required this.initialConfidence,
    required this.initialIoU,
    required this.initialAgnosticNMS,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late double _confidence;
  late double _iou;
  late bool _agnosticNMS;

  @override
  void initState() {
    super.initState();
    _confidence = widget.initialConfidence;
    _iou = widget.initialIoU;
    _agnosticNMS = widget.initialAgnosticNMS;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, {
          'confidence': _confidence,
          'iou': _iou,
          'agnosticNMS': _agnosticNMS,
        });
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Pengaturan"),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: "Kembali dan simpan pengaturan",
            onPressed: () {
              Navigator.pop(context, {
                'confidence': _confidence,
                'iou': _iou,
                'agnosticNMS': _agnosticNMS,
              });
            },
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              const Text("Confidence Threshold", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Semantics(
                label: "Penggeser, Ambang batas keyakinan, ${(_confidence * 100).round()} persen",
                child: Slider.adaptive(
                  value: _confidence,
                  min: 0.0,
                  max: 1.0,
                  divisions: 100,
                  label: "${(_confidence * 100).round()}%",
                  onChanged: (value) {
                    setState(() {
                      _confidence = value;
                    });
                  },
                ),
              ),
              const Text("Jika tinggi, hanya objek yang sangat jelas akan terdeteksi.", style: TextStyle(fontStyle: FontStyle.italic)),
              
              const SizedBox(height: 24),
              
              const Text("IoU Threshold", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Semantics(
                label: "Penggeser, Ambang batas IoU, ${(_iou * 100).round()} persen",
                child: Slider.adaptive(
                  value: _iou,
                  min: 0.0,
                  max: 1.0,
                  divisions: 100,
                  label: "${(_iou * 100).round()}%",
                  onChanged: (value) {
                    setState(() {
                      _iou = value;
                    });
                  },
                ),
              ),
              const Text("Jika tinggi, objek yang tumpang tindih akan terdeteksi.", style: TextStyle(fontStyle: FontStyle.italic)),

              const SizedBox(height: 24),

              Semantics(
                label: "Saklar, Agnostic NMS, ${ _agnosticNMS ? 'Aktif' : 'Nonaktif' }",
                child: SwitchListTile.adaptive(
                  title: const Text("Agnostic NMS", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  subtitle: const Text("Deteksi dengan label berbeda dianggap objek berbeda."),
                  value: _agnosticNMS,
                  onChanged: (value) {
                    setState(() {
                      _agnosticNMS = value;
                    });
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}