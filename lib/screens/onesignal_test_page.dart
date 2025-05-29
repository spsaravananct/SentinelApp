import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class OneSignalTestPage extends StatefulWidget {
  @override
  _OneSignalTestPageState createState() => _OneSignalTestPageState();
}

class _OneSignalTestPageState extends State<OneSignalTestPage> {
  String? _subscriptionId;
  String? _externalUserId;

  // Replace these with your actual OneSignal credentials
  static const String _appId = "f7eb2ffc-7c5a-4c4f-9bdb-2345f7ac9ec7";
  static const String _restApiKey = "os_v2_app_67vs77d4ljge7g63enc7ple6y6f26zwzcmwergvdxwn6tjo2d4amev4saorj7qsovkxm3zk6hwt6zgsz5ve5hs24pfhj44wcukpyusi";

  @override
  void initState() {
    super.initState();
    _loadSubscriptionInfo();
  }

  Future<void> _loadSubscriptionInfo() async {
    // Get current subscription ID
    String? subscriptionId = OneSignal.User.pushSubscription.id;
    setState(() {
      _subscriptionId = subscriptionId;
    });

    print('🔑 Current Subscription ID: $subscriptionId');
  }

  void _copySubscriptionId() {
    if (_subscriptionId != null) {
      Clipboard.setData(ClipboardData(text: _subscriptionId!));
      _showSnackBar('📋 Subscription ID copied!', Colors.green);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: Duration(seconds: 2),
      ),
    );
  }

  // Method to send notification using OneSignal REST API
  Future<bool> _sendNotificationViaAPI({
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    try {
      final url = Uri.parse('https://onesignal.com/api/v1/notifications');

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Basic $_restApiKey',
      };

      final body = {
        'app_id': _appId,
        'include_player_ids': [_subscriptionId], // Send to current device
        'headings': {'en': title},
        'contents': {'en': message},
        'data': data ?? {},
      };

      print('📤 Sending notification...');
      print('📤 URL: $url');
      print('📤 Body: ${jsonEncode(body)}');

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      print('📤 Response status: ${response.statusCode}');
      print('📤 Response body: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ Notification sent successfully!');
        return true;
      } else {
        print('❌ Failed to send notification: ${response.body}');
        return false;
      }

    } catch (e) {
      print('❌ Error sending notification: $e');
      return false;
    }
  }

  // Simulate sending emergency alert
  Future<void> _sendEmergencyAlert() async {
    if (_subscriptionId == null) {
      _showSnackBar('❌ Device not registered yet', Colors.red);
      return;
    }

    // For demo purposes - in real app, this would call your backend
    _showSnackBar('📤 Emergency alert would be sent to backend', Colors.orange);

    // Simulate what your backend would do:
    bool success = await _sendNotificationViaAPI(
      title: '🚨 EMERGENCY ALERT',
      message: 'Emergency protocol activated. Help is on the way!',
      data: {
        'type': 'emergency',
        'location': 'Current Location',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    if (success) {
      _showSnackBar('✅ Emergency alert sent!', Colors.green);
    } else {
      _showSnackBar('❌ Failed to send alert', Colors.red);
    }
  }

  // Send safety check reminder
  Future<void> _sendSafetyCheckReminder() async {
    if (_subscriptionId == null) {
      _showSnackBar('❌ Device not registered yet', Colors.red);
      return;
    }

    bool success = await _sendNotificationViaAPI(
      title: '🛡️ Safety Check',
      message: 'Time for your safety check-in. Tap to update status.',
      data: {
        'type': 'safety_check',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    if (success) {
      _showSnackBar('✅ Safety check sent!', Colors.blue);
    } else {
      _showSnackBar('❌ Failed to send reminder', Colors.red);
    }
  }

  // Send location alert
  Future<void> _sendLocationAlert() async {
    if (_subscriptionId == null) {
      _showSnackBar('❌ Device not registered yet', Colors.red);
      return;
    }

    bool success = await _sendNotificationViaAPI(
      title: '📍 Location Alert',
      message: 'You have reached your destination safely!',
      data: {
        'type': 'location_alert',
        'location': 'Destination',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    if (success) {
      _showSnackBar('✅ Location alert sent!', Colors.green);
    } else {
      _showSnackBar('❌ Failed to send alert', Colors.red);
    }
  }

  // Set external user ID (like phone number)
  Future<void> _setExternalUserId() async {
    String userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
    OneSignal.login(userId);

    setState(() {
      _externalUserId = userId;
    });

    _showSnackBar('👤 External User ID set: $userId', Colors.purple);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('🔔 OneSignal Test'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Device Info Card
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('🔑 Device Info',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        IconButton(
                          onPressed: _copySubscriptionId,
                          icon: Icon(Icons.copy, size: 20),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text('Subscription ID:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Container(
                      padding: EdgeInsets.all(8),
                      margin: EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _subscriptionId ?? 'Loading...',
                        style: TextStyle(fontSize: 10, fontFamily: 'monospace'),
                      ),
                    ),
                    if (_externalUserId != null) ...[
                      Text('External User ID:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(_externalUserId!, style: TextStyle(fontSize: 12)),
                    ],
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Warning Card
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber),
              ),
              child: Column(
                children: [
                  Text(
                    '⚠️ Important',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'To send real notifications, you need to add your OneSignal REST API Key above. Get it from OneSignal Dashboard → Settings → Keys & IDs',
                    style: TextStyle(fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            // Test Notification Buttons
            Text('🚨 Safety Notifications Test',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            SizedBox(height: 12),

            ElevatedButton(
              onPressed: _sendEmergencyAlert,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text('🚨 Send Emergency Alert'),
            ),

            SizedBox(height: 8),

            ElevatedButton(
              onPressed: _sendSafetyCheckReminder,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text('🛡️ Send Safety Check Reminder'),
            ),

            SizedBox(height: 8),

            ElevatedButton(
              onPressed: _sendLocationAlert,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text('📍 Send Location Alert'),
            ),

            SizedBox(height: 20),

            // User Management
            Text('👤 User Management',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            SizedBox(height: 12),

            ElevatedButton(
              onPressed: _setExternalUserId,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text('👤 Set External User ID'),
            ),

            SizedBox(height: 20),

            // Instructions
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Text(
                '💡 In a real app, your backend server would handle sending notifications to emergency contacts. This page demonstrates the API calls your backend would make.',
                style: TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),

            SizedBox(height: 20), // Add some bottom spacing
          ],
        ),
      ),
    );
  }
}