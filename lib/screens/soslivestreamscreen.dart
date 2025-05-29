import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_functions/cloud_functions.dart';

class SosLiveStreamScreen extends StatefulWidget {
  const SosLiveStreamScreen({super.key});

  @override
  State<SosLiveStreamScreen> createState() => _SosLiveStreamScreenState();
}

class _SosLiveStreamScreenState extends State<SosLiveStreamScreen> {
  int countdown = 10;
  Timer? timer;
  bool isStreaming = false;

  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  Future<void>? _initializeControllerFuture;

  String? deviceToken;

  @override
  void initState() {
    super.initState();
    initCamera();
    getFCMToken();
    startCountdown();
  }

  Future<void> getFCMToken() async {
    try {
      deviceToken = await FirebaseMessaging.instance.getToken();
      if (kDebugMode) {
        print("✅ Device FCM Token: $deviceToken");
      }
    } catch (e) {
      if (kDebugMode) {
        print("❌ Error getting FCM token: $e");
      }
    }
  }

  Future<void> initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _cameraController = CameraController(
          _cameras![0],
          ResolutionPreset.medium,
          enableAudio: true,
        );
        _initializeControllerFuture = _cameraController!.initialize();
        if (mounted) setState(() {});
      }
    } catch (e) {
      if (kDebugMode) {
        print("Camera initialization error: $e");
      }
    }
  }

  void startCountdown() {
    timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (countdown == 0) {
        t.cancel();
        startStream();
      } else {
        setState(() {
          countdown--;
        });
      }
    });
  }

  void startStream() {
    if (!isStreaming &&
        _cameraController != null &&
        _cameraController!.value.isInitialized) {
      setState(() {
        isStreaming = true;
      });

      if (kDebugMode) {
        print('📡 Live stream started');
      }

      sendSosAlert(); // 🔔 Trigger FCM alert
    }
  }

  Future<void> sendSosAlert() async {
    print("Failure");
    if (deviceToken == null) {
      if (kDebugMode) {
        print("❌ No device token available. Cannot send SOS alert.");
      }
      return;
    }

    try {
      final HttpsCallable callable =
      FirebaseFunctions.instance.httpsCallable('sendSosAlert');
      final response = await callable.call({'token': deviceToken});

      if (kDebugMode) {
        print("📨 Cloud Function Response: ${response.data}");
      }
    } catch (e) {
      if (kDebugMode) {
        print("❌ Error calling Cloud Function: $e");
      }
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new),
                    onPressed: () {
                      timer?.cancel();
                      Navigator.of(context).pop();
                    },
                  ),
                  const Spacer(),
                  const Text(
                    'sos',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const Spacer(flex: 2),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'SOS Live Stream',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.red),
              ),
              const SizedBox(height: 10),
              const Text(
                'Starting a SOS Live Stream and alerting\nyour emergency contacts',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 20),

              isStreaming
                  ? _cameraController != null
                  ? FutureBuilder(
                future: _initializeControllerFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.done) {
                    return SizedBox(
                      height: screenHeight * 0.6,
                      width: double.infinity,
                      child: CameraPreview(_cameraController!),
                    );
                  } else {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    );
                  }
                },
              )
                  : const Text('Camera not available')
                  : Column(
                children: [
                  const SizedBox(height: 20),
                  Container(
                    width: 100,
                    height: 100,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$countdown',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  GestureDetector(
                    onTap: () {
                      timer?.cancel();
                      startStream();
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF2196F3),
                            Color(0xFF1E88E5)
                          ],
                        ),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'Click to Start Stream',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  timer?.cancel();
                  Navigator.of(context).pop();
                },
                child: const Text(
                  'Cancel Stream',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
