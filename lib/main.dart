// ignore_for_file: depend_on_referenced_packages, library_private_types_in_public_api

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:withlive/setting.dart';
import 'package:flutter_blue/flutter_blue.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Withlive',
      theme: ThemeData(primarySwatch: Colors.grey),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  CameraController? _cameraController;
  WebSocketChannel? _webSocketChannel;
  Timer? _timer;
  final List<String> labelList = [
    "person",
    "bicycle",
    "car",
    "motorcycle",
    "airplane",
    "bus",
    "train",
    "truck",
    "boat",
    "traffic light",
    "fire hydrant",
    "stop sign",
    "parking meter",
    "bench",
    "bird",
    "cat",
    "dog",
    "horse",
    "sheep",
    "cow",
    "elephant",
    "bear",
    "zebra",
    "giraffe",
    "backpack",
    "umbrella",
    "handbag",
    "tie",
    "suitcase",
    "frisbee",
    "skis",
    "snowboard",
    "sports ball",
    "kite",
    "baseball bat",
    "baseball glove",
    "skateboard",
    "surfboard",
    "tennis racket",
    "bottle",
    "wine glass",
    "cup",
    "fork",
    "knife",
    "spoon",
    "bowl",
    "banana",
    "apple",
    "sandwich",
    "orange",
    "broccoli",
    "carrot",
    "hot dog",
    "pizza",
    "donut",
    "cake",
    "chair",
    "couch",
    "potted plant",
    "bed",
    "dining table",
    "toilet",
    "tv",
    "laptop",
    "mouse",
    "remote",
    "keyboard",
    "cell phone",
    "microwave",
    "oven",
    "toaster",
    "sink",
    "refrigerator",
    "book",
    "clock",
    "vase",
    "scissors",
    "teddy bear",
    "hair drier",
    "toothbrush",
    "tree",
    "pole",
    "fence",
    "utility_pole",
    "bollard",
    "flower_bed",
    "bus_stop",
    "traffic_cone",
    "kickboard",
    "streetlamp",
    "telephone_booth",
    "trash",
    "fire_plug",
    "plant",
    "sign_board",
    "corner",
    "opened_door",
    "mailbox",
    "unknown",
    "banner"
  ];

  final List<String> labelList1 = [
    'tree',
    'car',
    'person',
    'pole',
    'fence',
    'utility_pole',
    'bollard',
    'bicycle',
    'motorcycle',
    'flower_bed',
    'dog',
    'bus_stop',
    'traffic_cone',
    'truck',
    'bench',
    'bus',
    'kickboard',
    'streetlamp',
    'telephone_booth',
    'trash',
    'fire_plug',
    'plant',
    'sign_board',
    'fire_hydrant',
    'corner',
    'opened_door',
    'mailbox',
    'unknown',
    'banner'
  ];

  List<Map<String, dynamic>> _boundingBoxes = [];

  FlutterBlue flutterBlue = FlutterBlue.instance;

  @override
  void initState() {
    super.initState();
    initializeCamera().then((controller) {
      setState(() {
        _cameraController = controller;
      });
    });
    connectWebSocket(); // Connect to WebSocket
    _bluetoothInit(); // Initialize Bluetooth
  }

  void _bluetoothInit() {
    _startScan();
  }

  void _startScan() {
    flutterBlue.startScan(timeout: const Duration(seconds: 4));
    flutterBlue.scanResults.listen((results) {
      for (ScanResult result in results) {
        if (result.device.name == "Withlive") {
          _connectToDevice(result.device);
          break;
        }
      }
    });
  }

  void _connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect();
      print("블루투스 장치 연결 성공: ${device.name}");
    } catch (e) {
      print("연결 실패: $e");
    }
  }

  Future<CameraController> initializeCamera() async {
    final cameras = await availableCameras();

    if (cameras.isEmpty) {
      throw CameraException(
        'No cameras available',
        'Camera list is empty',
      );
    }

    final camera = cameras.first;
    final cameraController = CameraController(
      camera,
      ResolutionPreset.high,
    );
    await cameraController.initialize();
    return cameraController;
  }

  void connectWebSocket() {
    final channel = WebSocketChannel.connect(Uri.parse('ws://wsuk.dev:20000'));
    setState(() {
      _webSocketChannel = channel;
    });

    // Listen for received data and reconnect if necessary
    _webSocketChannel!.stream.listen((data) {
      setState(() {
        try {
          List<dynamic> jsonData = jsonDecode(data);
          _boundingBoxes = jsonData.cast<Map<String, dynamic>>();

          for (var box in _boundingBoxes) {
            box['label'] = box['label'].toString();
          }
        } catch (e) {
          print('Failed to parse JSON: $e');
        }
      });
    });

    // Send camera frames at a specified interval
    _timer = Timer.periodic(const Duration(milliseconds: 1000), (_) {
      if (_cameraController != null && _cameraController!.value.isInitialized) {
        sendCameraFrame();
      }
    });
  }

  void sendCameraFrame() async {
    if (_webSocketChannel == null) return;

    try {
      // Capture the current frame from the camera
      final cameraImage = await _cameraController!.takePicture();

      // Convert image data to base64
      final encodedImage = base64Encode(await cameraImage.readAsBytes());

      // Send the base64 encoded image data over WebSocket
      _webSocketChannel!.sink.add(encodedImage);
    } catch (e) {
      print('Failed to send camera frame: $e');
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _webSocketChannel?.sink.close();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Withlive'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const setting()),
              );
            },
          ),
        ],
        backgroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.white,
              child: Center(
                child: _cameraController != null &&
                        _cameraController!.value.isInitialized
                    ? Stack(
                        children: [
                          CameraPreview(_cameraController!),
                          for (var boundingBox in _boundingBoxes)
                            Positioned(
                              left: boundingBox['left'] * width,
                              top: boundingBox['top'] *
                                  (height - AppBar().preferredSize.height),
                              width: boundingBox['width'] * width,
                              height: boundingBox['height'] *
                                  (height - AppBar().preferredSize.height),
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.red,
                                    width: 2,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    labelList[int.parse(boundingBox['label'])],
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 25,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      )
                    : Container(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
