import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraPermissionScreen extends StatefulWidget {
  final VoidCallback onNext;

  const CameraPermissionScreen({super.key, required this.onNext});

  @override
  State<CameraPermissionScreen> createState() => _CameraPermissionScreenState();
}

class _CameraPermissionScreenState extends State<CameraPermissionScreen> {
  bool _isGranted = false;

  @override
  void initState() {
    super.initState();
    _checkPermissionStatus();
  }

  Future<void> _checkPermissionStatus() async {
    final status = await Permission.camera.status;
    setState(() {
      _isGranted = status.isGranted;
    });
  }

  Future<void> _requestPermission() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      widget.onNext();
    } else if (status.isPermanentlyDenied) {
      await openAppSettings();
    } else {
      // Permission denied but not permanently
      // Optionally show message or stay on screen
      _checkPermissionStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Camera Permission")),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.camera_alt, size: 100, color: Color(0xFF4285F4)),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                "Camera access is required to support SOS livestream and video calling feature within the app.",
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 30),
            _isGranted
                ? ElevatedButton(
              onPressed: widget.onNext,
              child: const Text("Permission Granted, Continue"),
            )
                : ElevatedButton(
              onPressed: _requestPermission,
              child: const Text("Allow Camera Permission"),
            ),
          ],
        ),
      ),
    );
  }
}
