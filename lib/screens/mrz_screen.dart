import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:aaaa_project/constants.dart';
import 'package:aaaa_project/models/mrz_info_model.dart';
import 'package:aaaa_project/screens/mrz_local.dart';
import 'package:aaaa_project/screens/nfc_screen.dart';
import 'package:aaaa_project/services/algerian_id_sdk.dart';
import 'dart:math' as math;

class MRZScreen extends StatefulWidget {
  const MRZScreen({Key? key}) : super(key: key);

  @override
  _MRZScreenState createState() => _MRZScreenState();
}

class _MRZScreenState extends State<MRZScreen> {
  CameraController? _cameraController;
  bool _isProcessing = false;
  bool _isMRZDetected = false;
  String _status = 'Initializing...';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startCamera();
    });
  }

  int _orientationToDegrees(DeviceOrientation orientation) {
    switch (orientation) {
      case DeviceOrientation.portraitUp:
        return 0;
      case DeviceOrientation.landscapeLeft:
        return 90;
      case DeviceOrientation.portraitDown:
        return 180;
      case DeviceOrientation.landscapeRight:
        return 270;
    }
  }

  Future<void> _startCamera() async {
    try {
      final cameras = await availableCameras();
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
      );

      _cameraController = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21, //IMPORTANT !!!  (must nv21)
      );

      await _cameraController!.initialize();

      // Set preferred orientation
      await _cameraController!.lockCaptureOrientation(
        DeviceOrientation.portraitUp,
      );

      _cameraController!.startImageStream(_processFrame);

      setState(() => _status = 'Scanning for MRZ...');
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  void _processFrame(CameraImage image) async {
    if (_isProcessing || _isMRZDetected) return;
    _isProcessing = true;

    try {
      if (image.planes.isEmpty) {
        _isProcessing = false;
        return;
      }

      // Get the correct plane (usually plane 0 for YUV format)
      final plane = image.planes[0];
      final bytes = plane.bytes;
      // Get rotation from camera controller
      final rotation =
          _cameraController?.value.deviceOrientation ??
          DeviceOrientation.portraitUp;

      // Convert DeviceOrientation to degrees
      int rotationDegrees = _orientationToDegrees(rotation);

      final result = await AlgerianIdSdk.detectTextFromFrame(
        frameData: bytes,
        width: image.width,
        height: image.height,
        rotation: rotationDegrees,
      );

      if (result['success'] == true && mounted) {
        setState(() {
          _isMRZDetected = true;
        });
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => NfcScreen(
              mrzInfoModel: MrzInfoModel.fromJson(result['mrzInfo']),
            ),
          ),
        );
      }
    } catch (e) {
      print('Frame processing error: $e');
    } finally {
      _isProcessing = false;
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Constants.str_primary_color,
        title: Text("MRZ Scanner", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        leading: InkWell(
          onTap: () {
            Navigator.pop(context);
          },
          child: Icon(Icons.arrow_back, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.photo_library, color: Colors.white),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => MrzLocal()),
              );
            },
            tooltip: 'Select Image',
          ),
        ],
      ),

      body: _cameraController?.value.isInitialized == true
          ? Column(
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    alignment: AlignmentGeometry.center,
                    children: [
                      CameraPreview(_cameraController!),
                      Positioned(
                        top: 200,
                        child: Transform.rotate(
                          angle: math.pi / 2,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.person,
                                  size: 100,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(18.0),
                                  child: SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width / 1.2,
                                    child: Text(
                                      "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(18.0),
                                  child: SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width / 1.2,
                                    child: LinearProgressIndicator(
                                      value: 0,
                                      backgroundColor: _isMRZDetected
                                          ? Colors.green
                                          : Colors.white,
                                      semanticsLabel:
                                          'Linear progress indicator',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(16),
                  color: Colors.black,
                  child: Row(
                    children: [
                      Icon(
                        _isMRZDetected ? Icons.check_circle : Icons.search,
                        color: _isMRZDetected ? Colors.green : Colors.white,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _status,
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text('Initializing Camera...'),
                ],
              ),
            ),
    );
  }
}
