import 'package:flutter/material.dart';

class RouteSafetyScreen extends StatelessWidget {
  const RouteSafetyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Static map background
          SizedBox.expand(
            child: Image.asset(
              'lib/image/map_screen.png',
              fit: BoxFit.cover,
            ),
          ),

          // Top search bar + SOS
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                  )
                ],
              ),
              child: const Row(
                children: [
                  Icon(Icons.my_location_outlined),
                  SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Current Location", style: TextStyle(fontSize: 14)),
                        Divider(height: 12),
                        Text("Choose Destination", style: TextStyle(fontSize: 14, color: Colors.black54)),
                      ],
                    ),
                  ),
                  SizedBox(width: 12),
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.red,
                    child: Text(
                      "SOS",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom route info card
          Positioned(
            bottom: 110,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("2.5 KM / 30 min", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Text("Safety : ", style: TextStyle(fontSize: 16)),
                      Text("75%", style: TextStyle(color: Colors.green, fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text("ETA  10:10 AM", style: TextStyle(fontSize: 16)),
                ],
              ),
            ),
          ),
        ],
      ),

      // Bottom Navigation
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: ""),
          BottomNavigationBarItem(
            icon: CircleAvatar(
              backgroundColor: Colors.blue,
              child: Icon(Icons.shield, color: Colors.white),
            ),
            label: "",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: ""),
        ],
      ),
    );
  }
}
