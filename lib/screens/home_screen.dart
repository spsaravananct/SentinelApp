import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../main.dart';
import 'safety_counter_screen.dart';
import 'emergency_contacts_screen.dart';

class HomeMapScreen extends StatefulWidget {
  const HomeMapScreen({super.key});

  @override
  State<HomeMapScreen> createState() => _HomeMapScreenState();
}

class _HomeMapScreenState extends State<HomeMapScreen> {
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(45.4215, -75.6991),
    zoom: 14,
  );

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _initFCM();
  }

  Future<void> _initFCM() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission();
    print('🔔 Permission status: ${settings.authorizationStatus}');

    String? token = await messaging.getToken();
    print('🔑 FCM Token: $token');

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        final title = message.notification!.title ?? "No Title";
        final body = message.notification!.body ?? "No Body";

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(body),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              )
            ],
          ),
        );
      }
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      const HomeMapBody(),
      const Center(child: Text("Sentinel Screen", style: TextStyle(fontSize: 24))),
      const Center(child: Text("Video Call Screen", style: TextStyle(fontSize: 24))),
    ];

    return Scaffold(
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shield),
            label: 'Sentinel',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.video_call),
            label: 'Video Call',
          ),
        ],
      ),
    );
  }
}

class HomeMapBody extends StatelessWidget {
  const HomeMapBody({super.key});

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(45.4215, -75.6991),
    zoom: 14,
  );

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const GoogleMap(
          initialCameraPosition: _initialPosition,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
        ),
        Positioned(
          top: 50,
          left: 20,
          child: GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/sos');
            },
            child: const CircleAvatar(
              radius: 25,
              backgroundColor: Colors.red,
              child: Text("SOS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
        Positioned(
          top: 50,
          left: 100,
          right: 100,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              shape: const StadiumBorder(),
            ),
            icon: const Icon(Icons.navigation, color: Colors.black),
            label: const Text("Live Location Sharing", style: TextStyle(color: Colors.black)),
            onPressed: () {
              Navigator.pushNamed(context, '/location-sharing');
            },
          ),
        ),
        Positioned(
          top: 50,
          right: 20,
          child: GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/notifications');
            },
            child: const Icon(Icons.notifications, color: Colors.black),
          ),
        ),
        Positioned(
          bottom: 320,
          left: 20,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              shape: const StadiumBorder(),
            ),
            icon: const Icon(Icons.location_on, color: Colors.blue),
            label: const Text("Check in", style: TextStyle(color: Colors.blue)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SafetyCounterScreen()),
              );
            },
          ),
        ),
        DraggableScrollableSheet(
          initialChildSize: 0.35,
          minChildSize: 0.2,
          maxChildSize: 0.6,
          builder: (context, controller) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              padding: const EdgeInsets.all(20),
              child: ListView(
                controller: controller,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Emergency Contacts", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => EmergencyContactsScreen()),
                          );
                        },
                        child: const Text("See more", style: TextStyle(color: Colors.blue)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const ContactTile(name: "Father"),
                  const ContactTile(name: "Mother"),
                  const ContactTile(name: "Brother"),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class ContactTile extends StatelessWidget {
  final String name;

  const ContactTile({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.purple[100],
            child: const Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                const Text("Today, 03:00pm", style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          const CircleAvatar(
            backgroundColor: Colors.blue,
            child: Icon(Icons.email, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
