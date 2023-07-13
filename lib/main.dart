// ignore_for_file: depend_on_referenced_packages

import 'dart:async';
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
    connectWebSocket(); // 웹 소켓 연결
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

    // 카메라 프레임을 지정된 간격으로 전송
    _timer = Timer.periodic(Duration(milliseconds: 10000), (_) {
      if (_cameraController != null && _cameraController!.value.isInitialized) {
        sendCameraFrame();
      }
    });
  }

  void sendCameraFrame() async {
    if (_webSocketChannel == null) return;

    try {
      // 카메라에서 현재 프레임 가져오기
      final cameraImage = await _cameraController!.takePicture();

      // 이미지 데이터를 Uint8List로 변환
      final imageBytes = await cameraImage.readAsBytes();
      final imageUint8List = Uint8List.fromList(imageBytes);

      // 이미지 데이터 압축 및 리사이징
      final compressedImage = compressAndResizeImage(imageUint8List);

      // 이미지 데이터 웹 소켓으로 전송
      _webSocketChannel!.sink.add(compressedImage);
    } catch (e) {
      print('Failed to send camera frame: $e');
    }
  }

  Uint8List compressAndResizeImage(Uint8List imageBytes) {
    final image = img.decodeImage(imageBytes);

    // 이미지 압축
    final compressedImage = img.encodeJpg(image!, quality: 80);

    // 이미지 리사이징
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
          title: Text('wihlife'),
          leading: const Icon(Icons.menu),
          actions: <Widget>[
            new IconButton(
              icon: new Icon(Icons.settings),
              tooltip: '설정',
              onPressed: () => {},
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
                    // 버튼이 눌렸을 때의 동작 처리
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
