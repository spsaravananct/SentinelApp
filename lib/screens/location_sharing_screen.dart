import 'package:flutter/material.dart';

class TrustedLocationSharingScreen extends StatefulWidget {
  const TrustedLocationSharingScreen({super.key});

  @override
  State<TrustedLocationSharingScreen> createState() =>
      _TrustedLocationSharingScreenState();
}

class _TrustedLocationSharingScreenState
    extends State<TrustedLocationSharingScreen> {
  int hours = 1;

  void incrementHour() {
    setState(() {
      hours++;
    });
  }

  void decrementHour() {
    if (hours > 1) {
      setState(() {
        hours--;
      });
    }
  }

  final List<Map<String, String>> contacts = [
    {'name': 'Father', 'time': 'Today, 03:00pm'},
    {'name': 'Mother', 'time': 'Today, 03:00pm'},
    {'name': 'Brother', 'time': 'Today, 03:00pm'},
    {'name': 'Sister', 'time': 'Today, 03:00pm'},
    {'name': 'Friend 1', 'time': 'Today, 03:00pm'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),
                const Expanded(
                  child: Text(
                    'Trusted Location Sharing',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const CircleAvatar(
                  backgroundColor: Colors.red,
                  radius: 18,
                  child: Text(
                    'SOS',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle, color: Colors.blue),
                onPressed: decrementHour,
              ),
              Text(
                '$hours:00',
                style:
                const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle, color: Colors.blue),
                onPressed: incrementHour,
              ),
              const Text(' hr', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              IconButton(
                icon: const Icon(Icons.send, color: Colors.blue),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Shared location for $hours hour(s)'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: contacts.length,
              itemBuilder: (context, index) {
                final contact = contacts[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 5,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.purpleAccent,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text(
                      contact['name'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(contact['time'] ?? ''),
                    trailing: const CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: Icon(Icons.mail, color: Colors.white),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
