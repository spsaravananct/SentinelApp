import 'package:flutter/material.dart';

class SentinelCompanionScreen extends StatelessWidget {
  const SentinelCompanionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sentinel Companion'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'Sentinel Companion Screen',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
