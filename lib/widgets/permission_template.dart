import 'package:flutter/material.dart';

class PermissionTemplate extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onAllow;

  const PermissionTemplate({super.key, 
    required this.icon,
    required this.title,
    required this.description,
    required this.onAllow,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 100, color: Colors.blueAccent),
            SizedBox(height: 32),
            Text(title, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            Text(description, textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: onAllow,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Text('Allow Access'),
              ),
            ),
            SizedBox(height: 20),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Maybe Later'),
            ),
          ],
        ),
      ),
    );
  }
}
