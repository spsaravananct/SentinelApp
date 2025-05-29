import 'dart:async';
import 'package:flutter/material.dart';
import 'soslivestreamscreen.dart'; // Ensure this file exists

class SafetyCounterScreen extends StatefulWidget {
  const SafetyCounterScreen({super.key});

  @override
  State<SafetyCounterScreen> createState() => _SafetyCounterScreenState();
}

class _SafetyCounterScreenState extends State<SafetyCounterScreen> {
  Duration countdownDuration = const Duration(minutes: 15);
  Duration initialDuration = const Duration(minutes: 15);
  Timer? timer;
  bool isRunning = false;

  void startTimer() {
    if (timer != null) timer!.cancel();
    setState(() => isRunning = true);
    timer = Timer.periodic(const Duration(seconds: 1), (_) => updateTimer());
  }

  void stopTimer() {
    if (timer != null) timer!.cancel();
    setState(() {
      isRunning = false;
      countdownDuration = initialDuration; // Reset the timer
    });
  }

  void updateTimer() {
    setState(() {
      final seconds = countdownDuration.inSeconds - 1;
      if (seconds < 0) {
        timer?.cancel();
        isRunning = false;
        showCheckDialog(); // Ask if the user is okay
      } else {
        countdownDuration = Duration(seconds: seconds);
      }
    });
  }

  void showCheckDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Are you okay?"),
          content: const Text("Please confirm if you're safe."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  countdownDuration = initialDuration;
                });
                startTimer(); // Restart the timer
              },
              child: const Text("Yes"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacementNamed(context, '/sos'); // ✅ updated route
              },
              child: const Text("No"),
            ),
          ],
        );
      },
    );
  }

  void changeTime({required bool increase, required bool isMinute}) {
    if (!isRunning) {
      final change = isMinute ? Duration(minutes: 1) : Duration(seconds: 10);
      setState(() {
        final newDuration = increase
            ? countdownDuration + change
            : countdownDuration - change >= const Duration(seconds: 10)
            ? countdownDuration - change
            : countdownDuration;
        countdownDuration = newDuration;
        initialDuration = newDuration;
      });
    }
  }

  String formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(duration.inMinutes)}:${twoDigits(duration.inSeconds.remainder(60))}';
  }

  @override
  Widget build(BuildContext context) {
    final timeString = formatTime(countdownDuration);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: true,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Counter',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Safety Countdown',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),

            // Big Counter Display
            Center(
              child: Container(
                width: 200,
                height: 120,
                alignment: Alignment.center,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade700,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  timeString,
                  style: const TextStyle(
                    fontSize: 48,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Config Row
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: isRunning
                  ? const SizedBox(height: 140)
                  : Column(
                key: const ValueKey('config-row'),
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle,
                              color: Colors.blue),
                          onPressed: () => changeTime(
                              increase: false, isMinute: true),
                        ),
                        Text(
                          '${initialDuration.inMinutes} min',
                          style: const TextStyle(fontSize: 18),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle,
                              color: Colors.blue),
                          onPressed: () => changeTime(
                              increase: true, isMinute: true),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle,
                              color: Colors.blue),
                          onPressed: () => changeTime(
                              increase: false, isMinute: false),
                        ),
                        Text(
                          '${initialDuration.inSeconds.remainder(60)} sec',
                          style: const TextStyle(fontSize: 18),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle,
                              color: Colors.blue),
                          onPressed: () => changeTime(
                              increase: true, isMinute: false),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Start Button
            ElevatedButton(
              onPressed: isRunning ? null : startTimer,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                padding:
                const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text("Start Counter"),
            ),

            const SizedBox(height: 20),

            // Stop Button
            ElevatedButton(
              onPressed: isRunning ? stopTimer : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding:
                const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text("Stop Counter"),
            ),
          ],
        ),
      ),
    );
  }
}
