import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:onesignal_flutter/onesignal_flutter.dart';

class FirebaseBackendService {
  // Your Firebase Cloud Function URLs
  static const String _baseUrl = "https://us-central1-mysentinal.cloudfunctions.net";

  static const String _sendEmergencyAlertUrl = "$_baseUrl/sendEmergencyAlert";
  static const String _sendSafetyCheckAlertUrl = "$_baseUrl/sendSafetyCheckAlert";
  static const String _sendLocationUpdateUrl = "$_baseUrl/sendLocationUpdate";
  static const String _sendLowBatteryAlertUrl = "$_baseUrl/sendLowBatteryAlert";
  static const String _testNotificationUrl = "$_baseUrl/testNotification";

  // Test function first
  static Future<bool> testConnection() async {
    try {
      String? currentPlayerId = OneSignal.User.pushSubscription.id;

      if (currentPlayerId == null) {
        print('❌ No player ID available');
        return false;
      }

      final response = await http.post(
        Uri.parse(_testNotificationUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'playerId': currentPlayerId,
        }),
      );

      print('🧪 Test response status: ${response.statusCode}');
      print('🧪 Test response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }

      return false;
    } catch (e) {
      print('❌ Test connection error: $e');
      return false;
    }
  }

  // Send Emergency Alert to multiple contacts
  static Future<Map<String, dynamic>> sendEmergencyAlert({
    required List<EmergencyContact> emergencyContacts,
    required String location,
    String? message,
    String? userName,
  }) async {
    try {
      String? userPlayerId = OneSignal.User.pushSubscription.id;

      if (userPlayerId == null) {
        return {
          'success': false,
          'error': 'User not registered with OneSignal'
        };
      }

      final requestBody = {
        'userPlayerId': userPlayerId,
        'emergencyContacts': emergencyContacts.map((contact) => contact.toJson()).toList(),
        'location': location,
        'message': message,
        'userName': userName ?? 'Safety App User',
      };

      print('🚨 Sending emergency alert...');
      print('📤 Request body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse(_sendEmergencyAlertUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      print('📥 Emergency alert response: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}: ${response.body}'
        };
      }

    } catch (e) {
      print('❌ Emergency alert error: $e');
      return {
        'success': false,
        'error': e.toString()
      };
    }
  }

  // Send Safety Check to contacts
  static Future<Map<String, dynamic>> sendSafetyCheckAlert({
    required List<EmergencyContact> emergencyContacts,
    required String status,
    required String location,
    String? userName,
  }) async {
    try {
      String? userPlayerId = OneSignal.User.pushSubscription.id;

      if (userPlayerId == null) {
        return {
          'success': false,
          'error': 'User not registered with OneSignal'
        };
      }

      final requestBody = {
        'userPlayerId': userPlayerId,
        'emergencyContacts': emergencyContacts.map((contact) => contact.toJson()).toList(),
        'status': status,
        'location': location,
        'userName': userName ?? 'Safety App User',
      };

      print('🛡️ Sending safety check...');

      final response = await http.post(
        Uri.parse(_sendSafetyCheckAlertUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      print('📥 Safety check response: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}: ${response.body}'
        };
      }

    } catch (e) {
      print('❌ Safety check error: $e');
      return {
        'success': false,
        'error': e.toString()
      };
    }
  }

  // Send Location Update
  static Future<Map<String, dynamic>> sendLocationUpdate({
    required List<EmergencyContact> emergencyContacts,
    required String location,
    String? locationName,
    String? userName,
  }) async {
    try {
      String? userPlayerId = OneSignal.User.pushSubscription.id;

      if (userPlayerId == null) {
        return {
          'success': false,
          'error': 'User not registered with OneSignal'
        };
      }

      final requestBody = {
        'userPlayerId': userPlayerId,
        'emergencyContacts': emergencyContacts.map((contact) => contact.toJson()).toList(),
        'location': location,
        'locationName': locationName,
        'userName': userName ?? 'Safety App User',
      };

      print('📍 Sending location update...');

      final response = await http.post(
        Uri.parse(_sendLocationUpdateUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      print('📥 Location update response: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}: ${response.body}'
        };
      }

    } catch (e) {
      print('❌ Location update error: $e');
      return {
        'success': false,
        'error': e.toString()
      };
    }
  }

  // Send Low Battery Alert
  static Future<Map<String, dynamic>> sendLowBatteryAlert({
    required List<EmergencyContact> emergencyContacts,
    required int batteryLevel,
    required String location,
    String? userName,
  }) async {
    try {
      String? userPlayerId = OneSignal.User.pushSubscription.id;

      if (userPlayerId == null) {
        return {
          'success': false,
          'error': 'User not registered with OneSignal'
        };
      }

      final requestBody = {
        'userPlayerId': userPlayerId,
        'emergencyContacts': emergencyContacts.map((contact) => contact.toJson()).toList(),
        'batteryLevel': batteryLevel,
        'location': location,
        'userName': userName ?? 'Safety App User',
      };

      print('🔋 Sending low battery alert...');

      final response = await http.post(
        Uri.parse(_sendLowBatteryAlertUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      print('📥 Low battery response: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}: ${response.body}'
        };
      }

    } catch (e) {
      print('❌ Low battery alert error: $e');
      return {
        'success': false,
        'error': e.toString()
      };
    }
  }
}

// Emergency Contact Model
class EmergencyContact {
  final String name;
  final String phone;
  final String? playerId; // OneSignal Player ID
  final String? email;

  EmergencyContact({
    required this.name,
    required this.phone,
    this.playerId,
    this.email,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'playerId': playerId,
      'email': email,
    };
  }

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      name: json['name'],
      phone: json['phone'],
      playerId: json['playerId'],
      email: json['email'],
    );
  }
}

// Test Page for Backend Integration
class BackendTestPage extends StatefulWidget {
  @override
  _BackendTestPageState createState() => _BackendTestPageState();
}

class _BackendTestPageState extends State<BackendTestPage> {
  bool _isLoading = false;
  String? _lastResult;

  // Sample emergency contacts for testing
  final List<EmergencyContact> _testContacts = [
    EmergencyContact(
      name: "Test Contact 1",
      phone: "+1234567890",
      playerId: "4655a032-9714-44b3-afc0-c5ef028ab93c", // Your current player ID for testing
    ),
    // Add more test contacts with their actual OneSignal Player IDs
  ];

  void _showResult(String result) {
    setState(() {
      _lastResult = result;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result),
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
    });

    bool success = await FirebaseBackendService.testConnection();

    setState(() {
      _isLoading = false;
    });

    if (success) {
      _showResult('✅ Backend connection successful!');
    } else {
      _showResult('❌ Backend connection failed');
    }
  }

  Future<void> _testEmergencyAlert() async {
    setState(() {
      _isLoading = true;
    });

    final result = await FirebaseBackendService.sendEmergencyAlert(
      emergencyContacts: _testContacts,
      location: "Test Location - Lat: 37.7749, Lng: -122.4194",
      message: "This is a test emergency alert from Flutter app!",
      userName: "Test User",
    );

    setState(() {
      _isLoading = false;
    });

    if (result['success'] == true) {
      _showResult('✅ Emergency alert sent to ${result['contactsNotified']} contacts!');
    } else {
      _showResult('❌ Failed: ${result['error']}');
    }
  }

  Future<void> _testSafetyCheck() async {
    setState(() {
      _isLoading = true;
    });

    final result = await FirebaseBackendService.sendSafetyCheckAlert(
      emergencyContacts: _testContacts,
      status: "Safe and sound",
      location: "Home - Test Location",
      userName: "Test User",
    );

    setState(() {
      _isLoading = false;
    });

    if (result['success'] == true) {
      _showResult('✅ Safety check sent successfully!');
    } else {
      _showResult('❌ Failed: ${result['error']}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('🔥 Backend Test'),
        backgroundColor: Colors.deepOrange,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('🔥 Firebase Backend Status',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    SizedBox(height: 8),
                    Text('Functions URL: us-central1-mysentinal.cloudfunctions.net'),
                    SizedBox(height: 8),
                    Text('Test Contacts: ${_testContacts.length}'),
                    if (_lastResult != null) ...[
                      SizedBox(height: 8),
                      Text('Last Result:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(_lastResult!, style: TextStyle(fontSize: 12)),
                    ],
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // Test Buttons
            Text('🧪 Backend Tests',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            SizedBox(height: 12),

            ElevatedButton(
              onPressed: _isLoading ? null : _testConnection,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text('🧪 Test Connection'),
            ),

            SizedBox(height: 8),

            ElevatedButton(
              onPressed: _isLoading ? null : _testEmergencyAlert,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text('🚨 Test Emergency Alert'),
            ),

            SizedBox(height: 8),

            ElevatedButton(
              onPressed: _isLoading ? null : _testSafetyCheck,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text('🛡️ Test Safety Check'),
            ),

            SizedBox(height: 20),

            // Instructions
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('📝 Instructions:', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('1. Test Connection first', style: TextStyle(fontSize: 12)),
                  Text('2. Try Emergency Alert (will send to your device)', style: TextStyle(fontSize: 12)),
                  Text('3. Check console logs for detailed responses', style: TextStyle(fontSize: 12)),
                  Text('4. Add real emergency contacts with their Player IDs', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),

            SizedBox(height: 20), // Add bottom spacing
          ],
        ),
      ),
    );
  }
}