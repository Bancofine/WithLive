// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

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

  @override
  void initState() {
    super.initState();
    initializeCamera().then((controller) {
      setState(() {
        _cameraController = controller;
      });
    });
  }

  @override
  void dispose() {
    _cameraController?.dispose();
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
