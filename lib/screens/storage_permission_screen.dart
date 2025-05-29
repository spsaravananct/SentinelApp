import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../widgets/permission_template.dart';

class StoragePermissionScreen extends StatelessWidget {
  final VoidCallback onNext;

  const StoragePermissionScreen({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return PermissionTemplate(
      icon: Icons.folder,
      title: 'Allow Storage Access',
      description: 'Storage access is needed to save shared media from video calls and to securely store emergency session logs.',
      onAllow: () async {
        final status = await Permission.storage.request();
        if (status.isGranted) {
          onNext();
        } else if (status.isPermanentlyDenied) {
          openAppSettings();
        }
      },
    );
  }
}
