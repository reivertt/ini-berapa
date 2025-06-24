import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart';
import 'package:ini_berapa/utils/nms.dart';
import 'package:flutter/services.dart' show rootBundle;

class YoloModel {
  final String modelPath;
  final int inWidth;
  final int inHeight;
  final int numClasses;
  Interpreter? _interpreter;

  YoloModel(
      this.modelPath,
      this.inWidth,
      this.inHeight,
      this.numClasses,
      );

  Future<void> init() async {
    try {
      initializeInterpreter().then((interpreter) {
          _interpreter = interpreter;
      }).catchError((error) {
        print(error);
      });
      debugPrint("Interpreter initialized successfully with GPU delegate.");
    } catch (e) {
      debugPrint("Failed to initialize interpreter: $e");
    }

  }

  Future<Interpreter> initializeInterpreter() async {
    Interpreter interpreter;

    // --- First, try to load with the GPU delegate ---
    try {
      print("Attempting to load model with GPU delegate...");
      final gpuDelegate = GpuDelegateV2();
      // final gpuDelegate = GpuDelegateV2(
      //   options: GpuDelegateOptionsV2(
      //     isPrecisionLossAllowed: false,
      //     inferencePreference: TfLiteGpuInferenceUsage.fastSingleAnswer,
      //     inferencePriority1: TfLiteGpuInferencePriority.minLatency,
      //     inferencePriority2: TfLiteGpuInferencePriority.auto,
      //     inferencePriority3: TfLiteGpuInferencePriority.auto,
      //   ),
      // );

      var interpreterOptions = InterpreterOptions()..addDelegate(gpuDelegate);
      interpreter = await Interpreter.fromAsset(
        modelPath,
        options: interpreterOptions,
      );
      print("Interpreter loaded successfully with GPU delegate.");
      return interpreter;
    } catch (e) {
      print('Failed to load model with GPU delegate: $e');
      print('Retrying without a delegate...');
    }

    // --- If GPU fails, fall back to CPU ---
    try {
      var interpreterOptions = InterpreterOptions();
      interpreter = await Interpreter.fromAsset(
        modelPath,
        options: interpreterOptions, // No delegate, uses CPU
      );
      print("Interpreter loaded successfully on CPU.");
      return interpreter;
    } catch (e) {
      print('Failed to load model on CPU.');
      // Handle the error appropriately in your app
      throw Exception('Could not initialize the TFLite interpreter.');
    }
  }

  List<List<double>> infer(Image image) {
    assert(_interpreter != null, 'The model must be initialized');

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
    // 4 + 10: left, top, right, bottom and probabilities for each class
    // 13125: num predictions
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
