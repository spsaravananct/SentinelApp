import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationPermissionScreen extends StatefulWidget {
  final VoidCallback onNext;

  const LocationPermissionScreen({super.key, required this.onNext});

  @override
  State<LocationPermissionScreen> createState() => _LocationPermissionScreenState();
}

class _LocationPermissionScreenState extends State<LocationPermissionScreen> {
  bool _isGranted = false;

  @override
  void initState() {
    super.initState();
    _checkPermissionStatus();
  }

  Future<void> _checkPermissionStatus() async {
    final status = await Permission.location.status;
    setState(() {
      _isGranted = status.isGranted;
    });
  }

  Future<void> _requestPermission() async {
    final status = await Permission.location.request();
    if (status.isGranted) {
      widget.onNext();
    } else if (status.isPermanentlyDenied) {
      await openAppSettings();
    } else {
      _checkPermissionStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Location Permission")),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_on, size: 100, color: Color(0xFF4285F4)),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                "Location access is used to share your real-time position during emergencies and suggest safer routes.",
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
              child: const Text("Allow Location Permission"),
            ),
          ],
        ),
      ),
    );
  }
}
