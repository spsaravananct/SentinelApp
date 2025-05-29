import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class MicPermissionScreen extends StatefulWidget {
  final VoidCallback onNext;

  const MicPermissionScreen({super.key, required this.onNext});

  @override
  State<MicPermissionScreen> createState() => _MicPermissionScreenState();
}

class _MicPermissionScreenState extends State<MicPermissionScreen> {
  bool _isGranted = false;

  @override
  void initState() {
    super.initState();
    _checkPermissionStatus();
  }

  Future<void> _checkPermissionStatus() async {
    final status = await Permission.microphone.status;
    setState(() {
      _isGranted = status.isGranted;
    });
  }

  Future<void> _requestPermission() async {
    final status = await Permission.microphone.request();
    if (status.isGranted) {
      widget.onNext();
    } else if (status.isPermanentlyDenied) {
      await openAppSettings();
    } else {
      _checkPermissionStatus(); // Refresh status on denial
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Microphone Permission")),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.mic, size: 100, color: Color(0xFF4285F4)),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                "Microphone access is essential to enable real-time voice communication during SOS events and video calls.",
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
              child: const Text("Allow Microphone Permission"),
            ),
          ],
        ),
      ),
    );
  }
}
