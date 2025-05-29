import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../widgets/permission_template.dart';

class NotificationPermissionScreen extends StatelessWidget {
  final VoidCallback onNext;

  const NotificationPermissionScreen({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return PermissionTemplate(
      icon: Icons.notifications,
      title: 'Allow Notification Access',
      description: 'Notification permission ensures you receive important safety alerts, check-ins, and emergency updates.',
      onAllow: () async {
        final status = await Permission.notification.request();
        if (status.isGranted) {
          onNext();
        } else if (status.isPermanentlyDenied) {
          openAppSettings();
        }
      },
    );
  }
}
