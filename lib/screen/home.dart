import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:ini_berapa/utils/bbox.dart';
import 'package:ini_berapa/utils/labels.dart';
import 'package:ini_berapa/utils/yolo.dart';

// Function to convert CameraImage to img.Image
img.Image? convertCameraImage(CameraImage cameraImage) {
  if (cameraImage.format.group == ImageFormatGroup.yuv420) {
    return _convertYUV420(cameraImage);
  } else if (cameraImage.format.group == ImageFormatGroup.bgra8888) {
    return _convertBGRA8888(cameraImage);
  }
  return null;
}

img.Image _convertBGRA8888(CameraImage image) {
  // This conversion is for iOS.
  return img.Image.fromBytes(
    width: image.width,
    height: image.height,
    bytes: image.planes[0].bytes.buffer,
    order: img.ChannelOrder.bgra,
  );
}

img.Image _convertYUV420(CameraImage image) {
  // This conversion is for Android.
  final int width = image.width;
  final int height = image.height;
  final int uvRowStride = image.planes[1].bytesPerRow;
  final int uvPixelStride = image.planes[1].bytesPerPixel!;

  final imageResult = img.Image(width: width, height: height);

  for (int y = 0; y < height; y++) {
    final int uvIndex = uvRowStride * (y >> 1);
    for (int x = 0; x < width; x++) {
      final int uvIndex2 = (uvIndex + (x >> 1) * uvPixelStride);
      final int yIndex = y * width + x;

      final int yValue = image.planes[0].bytes[yIndex];
      final int uValue = image.planes[1].bytes[uvIndex2];
      final int vValue = image.planes[2].bytes[uvIndex2];

      int r = (yValue + (1.402 * (vValue - 128))).round();
      int g =
      (yValue - (0.344136 * (uValue - 128)) - (0.714136 * (vValue - 128)))
          .round();
      int b = (yValue + (1.772 * (uValue - 128))).round();

      r = r.clamp(0, 255);
      g = g.clamp(0, 255);
      b = b.clamp(0, 255);

      imageResult.setPixelRgba(x, y, r, g, b, 255);
    }
  }

  return imageResult;
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const inModelWidth = 800;
  static const inModelHeight = 800;
  static const numClasses = 10;

  final YoloModel model = YoloModel(
    'assets/models/yolov8n.tflite',
    inModelWidth,
    inModelHeight,
    numClasses,
  );

  // You can adjust this threshold in real-time if needed, but start low for debugging.
  double confidenceThreshold = 0.7; // Start with a low threshold
  double iouThreshold = 0.1;
  bool agnosticNMS = false;

  List<List<double>>? inferenceOutput;
  List<Bbox> bboxesWidgets = []; // Directly store the final widgets

  CameraController? cameraController;
  bool isDetecting = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    debugPrint("--- App Initialization Started ---");
    await model.init();

    await _initializeCamera();
    if (mounted) {
      setState(() {
        isLoading = false;
        debugPrint("--- App Initialization Finished: Showing Camera Preview ---");
      });
    }
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    cameraController = CameraController(cameras[0], ResolutionPreset.high, enableAudio: false);
    await cameraController!.initialize();
    if (mounted) {
      debugPrint("--- Camera Initialized Successfully ---");
      debugPrint("Camera resolution: ${cameraController!.value.previewSize}");
      cameraController!.startImageStream(_processCameraImage);
    }
  }

  void _processCameraImage(CameraImage image) {
    if (isDetecting) return;

    isDetecting = true;
    try {
      debugPrint("\n--- [START] Processing Camera Frame ---");

      final convertedImage = convertCameraImage(image);
      if (convertedImage == null) {
        debugPrint("[ERROR] Image conversion failed. Converted image is null.");
        isDetecting = false;
        return;
      }
      debugPrint("Step 1: Image converted successfully. Original size: ${convertedImage.width}x${convertedImage.height}");

      // 2. Run inference on the converted image.
      debugPrint("Step 2: Running model inference...");
      inferenceOutput = model.infer(convertedImage);
      debugPrint("Step 2: Model inference complete.");

      // 3. Check the raw output from the model to see if it's producing scores.
      if (inferenceOutput != null) {
        double maxScore = 0.0;
        for (int i = 4; i < (4 + numClasses); i++) {
          for (double score in inferenceOutput![i]) {
            if (score > maxScore) {
              maxScore = score;
            }
          }
        }
        debugPrint("Step 3: Raw model output check - Highest confidence score found: $maxScore");
        if (maxScore < confidenceThreshold) {
          debugPrint("Step 3: Highest score is BELOW the confidence threshold ($confidenceThreshold). No boxes will be shown.");
        }
      } else {
        debugPrint("[ERROR] Model output (inferenceOutput) is null.");
      }

      // 4. Run post-processing to filter boxes based on confidence.
      updatePostprocess(convertedImage.width, convertedImage.height);

    } catch (e, stackTrace) {
      debugPrint("[FATAL ERROR] An exception occurred during image processing: $e");
      debugPrint("Stack trace: $stackTrace");
    } finally {
      isDetecting = false;
      debugPrint("--- [END] Frame Processing Finished ---");
    }
  }

  void updatePostprocess(int imageWidth, int imageHeight) {
    debugPrint("Step 4: Running post-processing...");
    if (inferenceOutput == null) {
      debugPrint("Step 4: SKIPPED - inferenceOutput is null.");
      return;
    }

    final (classes, bboxes, scores) = model.postprocess(
      inferenceOutput!,
      imageWidth,
      imageHeight,
      confidenceThreshold: confidenceThreshold, // Use the adjustable threshold
      iouThreshold: iouThreshold,
      agnostic: agnosticNMS,
    );

    debugPrint("Step 4: Post-processing complete. Found ${bboxes.length} bounding boxes.");

    // 5. Create the Bbox widgets to be drawn on the screen.
    final newBboxesWidgets = _createBboxWidgets(classes, bboxes, scores, imageWidth, imageHeight);
    debugPrint("Step 5: Created ${newBboxesWidgets.length} Bbox widgets.");

    // 6. Update the UI.
    if (mounted) {
      setState(() {
        debugPrint("Step 6: Calling setState to redraw UI with new boxes.");
        bboxesWidgets = newBboxesWidgets;
      });
    }
  }

  List<Bbox> _createBboxWidgets(List<int> classes, List<List<double>> bboxes, List<double> scores, int imageWidth, int imageHeight) {
    final List<Bbox> widgets = [];
    final List<Color> bboxesColors = List.generate(
      numClasses,
          (_) => Color((Random().nextDouble() * 0xFFFFFF).toInt()).withAlpha(255),
    );
    final double scaleX = MediaQuery.of(context).size.width / imageWidth;
    final double scaleY = MediaQuery.of(context).size.height / imageHeight;

    for (int i = 0; i < bboxes.length; i++) {
      final box = bboxes[i];
      final boxClass = classes[i];
      widgets.add(
        Bbox(
            box[0] * scaleX,
            box[1] * scaleY,
            box[2] * scaleX,
            box[3] * scaleY,
            labels[boxClass],
            scores[i],
            bboxesColors[boxClass]),
      );
    }
    return widgets;
  }


  @override
  void dispose() {
    debugPrint("--- HomePage dispose: Disposing camera controller ---");
    cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (cameraController == null || !cameraController!.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text("Initializing Model and Camera..."),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Ini Berapa?')),
      body: Stack(
        children: [
          SizedBox(
              width: MediaQuery.of(context).size.width,
              child: CameraPreview(cameraController!)),
          ...bboxesWidgets,
        ],
      ),
    );

  }
}