import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart'; // Temporarily disabled
import 'package:image/image.dart';
import 'package:ini_berapa/utils/nms.dart';

class YoloModel {
  final String modelPath;
  final int inWidth;
  final int inHeight;
  final int numClasses;
  Interpreter? _interpreter; // Temporarily disabled

  YoloModel(
      this.modelPath,
      this.inWidth,
      this.inHeight,
      this.numClasses,
      );

  Future<void> init() async {
    _interpreter = await Interpreter.fromAsset(modelPath); // Temporarily disabled
    // print('YoloModel init called - TensorFlow Lite temporarily disabled');
  }

  List<List<double>> infer(Image image) {
    assert(_interpreter != null, 'The model must be initialized'); // Temporarily disabled
    // print('YoloModel infer called - returning mock data');
    
    // Return mock detection data for testing
    // return [
    //   [100.0, 100.0, 200.0, 200.0, 0.9, 0.0], // Mock detection: x, y, w, h, confidence, class
    // ];

    final imgResized = copyResize(image, width: inWidth, height: inHeight);
    final Float32List floatData = Float32List(inHeight * inWidth * 3);
    int floatIndex = 0;
    for (int y = 0; y < inHeight; y++) {
      for (int x = 0; x < inWidth; x++) {
        final pixel = imgResized.getPixel(x, y);
        floatData[floatIndex++] = pixel.rNormalized.toDouble();
        floatData[floatIndex++] = pixel.gNormalized.toDouble();
        floatData[floatIndex++] = pixel.bNormalized.toDouble();
      }
    }
    final Uint8List imgUint8 = Uint8List.view(floatData.buffer);

    // output shape:
    // 1 : batch size
    // 4 + 80: left, top, right, bottom and probabilities for each class
    // 8400: num predictions
    final output = [
      List<List<double>>.filled(4 + numClasses, List<double>.filled(13125, 0))
    ];
    int predictionTimeStart = DateTime.now().millisecondsSinceEpoch;
    _interpreter!.run(imgUint8, output);
    debugPrint(
        'Prediction time: ${DateTime.now().millisecondsSinceEpoch - predictionTimeStart} ms');
    return output[0];

  }

  (List<int>, List<List<double>>, List<double>) postprocess(
      List<List<double>> unfilteredBboxes,
      int imageWidth,
      int imageHeight, {
        double confidenceThreshold = 0.7,
        double iouThreshold = 0.1,
        bool agnostic = false,
      }) {
    // Mock postprocessing for testing
    // return (
    //   [0], // Mock class
    //   [[100.0, 100.0, 200.0, 200.0]], // Mock bbox
    //   [0.9], // Mock score
    // );
    

    List<int> classes;
    List<List<double>> bboxes;
    List<double> scores;
    int nmsTimeStart = DateTime.now().millisecondsSinceEpoch;
    (classes, bboxes, scores) = nms(
      unfilteredBboxes,
      confidenceThreshold: confidenceThreshold,
      iouThreshold: iouThreshold,
      agnostic: agnostic,
    );
    debugPrint(
        'NMS time: ${DateTime.now().millisecondsSinceEpoch - nmsTimeStart} ms');
    for (var bbox in bboxes) {
      bbox[0] *= imageWidth;
      bbox[1] *= imageHeight;
      bbox[2] *= imageWidth;
      bbox[3] *= imageHeight;
    }
    return (classes, bboxes, scores);

  }

  (List<int>, List<List<double>>, List<double>) inferAndPostprocess(
      Image image, {
        double confidenceThreshold = 0.7,
        double iouThreshold = 0.1,
        bool agnostic = false,
      }) =>
      postprocess(
        infer(image),
        image.width,
        image.height,
        confidenceThreshold: confidenceThreshold,
        iouThreshold: iouThreshold,
        agnostic: agnostic,
      );
}
