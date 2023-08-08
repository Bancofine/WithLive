// ignore_for_file: depend_on_referenced_packages

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:image/image.dart' as img;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'wihlife',
      theme: ThemeData(primarySwatch: Colors.grey),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  CameraController? _cameraController;
  WebSocketChannel? _webSocketChannel;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    initializeCamera().then((controller) {
      setState(() {
        _cameraController = controller;
      });
    });
    connectWebSocket(); // Connect to WebSocket
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _webSocketChannel?.sink.close();
    _timer?.cancel();
    super.dispose();
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

    // Send camera frames at a specified interval
    _timer = Timer.periodic(Duration(milliseconds: 10000), (_) {
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

  Uint8List compressAndResizeImage(Uint8List imageBytes) {
    final image = img.decodeImage(imageBytes);

    if (image == null) {
      throw Exception('Failed to decode image');
    }

    // Compress the image
    final compressedImage = img.encodeJpg(image as img.Image, quality: 80);

    // Resize the image
    final resizedImage =
        img.copyResize(compressedImage as img.Image, width: 800);

    return resizedImage.getBytes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(70.0),
        child: AppBar(
          title: Text('Withlive'),
          leading: const Icon(Icons.menu),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.settings),
              tooltip: '설정',
              onPressed: () {},
            ),
          ],
          backgroundColor: Colors.white,
        ),
      ),
      body: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: '',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.white,
              child: Center(
                child: _cameraController != null &&
                        _cameraController!.value.isInitialized
                    ? AspectRatio(
                        aspectRatio: _cameraController!.value.aspectRatio,
                        child: CameraPreview(_cameraController!),
                      )
                    : Container(),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.white,
              child: Center(
                child: ElevatedButton(
                  onPressed: () {
                    // Handle button press
                  },
                  child: Text('큰 버튼'),
                  style: ButtonStyle(
                    fixedSize: MaterialStateProperty.all<Size>(
                      Size(350.0, 330.0),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
