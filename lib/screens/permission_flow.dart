import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Import individual permission screens
import 'camera_permission_screen.dart';
import 'mic_permission_screen.dart';
import 'location_permission_screen.dart';
 // Add this import
// Optionally add notification_permission_screen.dart if using Firebase Messaging

class PermissionFlow extends StatefulWidget {
  const PermissionFlow({super.key});

  @override
  State<PermissionFlow> createState() => _PermissionFlowState();
}

class _PermissionFlowState extends State<PermissionFlow> {
  late final List<Widget Function(VoidCallback)> _permissionScreens;
  int _currentScreenIndex = 0;

  @override
  void initState() {
    super.initState();

    _permissionScreens = [
          (onNext) => CameraPermissionScreen(onNext: onNext),
          (onNext) => MicPermissionScreen(onNext: onNext),
          (onNext) => LocationPermissionScreen(onNext: onNext), // Added contacts permission
      // Add more permission screens here, e.g. NotificationsPermissionScreen(onNext: onNext),
    ];
  }

  void onNext() async {
    if (_currentScreenIndex < _permissionScreens.length - 1) {
      setState(() {
        _currentScreenIndex++;
      });
    } else {
      // All permissions granted → store flag and navigate to home
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('permissions_given', true);

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_permissionScreens.isEmpty || _currentScreenIndex >= _permissionScreens.length) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return _permissionScreens[_currentScreenIndex](onNext);
  }
}