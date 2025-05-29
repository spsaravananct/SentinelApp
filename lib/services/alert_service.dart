import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:battery_plus/battery_plus.dart';

/// 🛡️ Centralized Safety Alert Service
/// Use this service from anywhere in your app to send safety alerts
class SafetyAlertService {

  // Firebase Cloud Function URLs
  static const String _baseUrl = "https://us-central1-mysentinal.cloudfunctions.net";

  // User settings (you can load these from SharedPreferences or Firebase)
  static String? _userName;
  static List<EmergencyContact> _emergencyContacts = [];

  /// Initialize the service with user data
  static Future<void> initialize({
    String? userName,
    List<EmergencyContact>? emergencyContacts,
  }) async {
    _userName = userName;
    _emergencyContacts = emergencyContacts ?? [];

    print('🛡️ Safety Alert Service initialized');
    print('👤 User: $_userName');
    print('👥 Emergency Contacts: ${_emergencyContacts.length}');
  }

  /// Add or update emergency contacts
  static void updateEmergencyContacts(List<EmergencyContact> contacts) {
    _emergencyContacts = contacts;
    print('👥 Updated emergency contacts: ${contacts.length}');
  }

  /// Set user name
  static void setUserName(String userName) {
    _userName = userName;
    print('👤 Updated user name: $userName');
  }

  /// Get current location as string
  static Future<String> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition();
      return "Lat: ${position.latitude.toStringAsFixed(6)}, Lng: ${position.longitude.toStringAsFixed(6)}";
    } catch (e) {
      print('❌ Location error: $e');
      return "Location unavailable";
    }
  }

  /// 🚨 EMERGENCY ALERT - Call from anywhere in your app
  static Future<SafetyAlertResult> sendEmergencyAlert({
    String? customMessage,
    String? customLocation,
  }) async {
    try {
      print('🚨 EMERGENCY ALERT TRIGGERED');

      String? userPlayerId = OneSignal.User.pushSubscription.id;
      if (userPlayerId == null) {
        return SafetyAlertResult.error('OneSignal not initialized');
      }

      if (_emergencyContacts.isEmpty) {
        return SafetyAlertResult.error('No emergency contacts configured');
      }

      String location = customLocation ?? await _getCurrentLocation();

      final response = await http.post(
        Uri.parse('$_baseUrl/sendEmergencyAlert'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userPlayerId': userPlayerId,
          'emergencyContacts': _emergencyContacts.map((c) => c.toJson()).toList(),
          'location': location,
          'message': customMessage,
          'userName': _userName ?? 'Safety App User',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          print('✅ Emergency alert sent to ${data['contactsNotified']} contacts');
          return SafetyAlertResult.success(
              'Emergency alert sent to ${data['contactsNotified']} contacts'
          );
        }
      }

      return SafetyAlertResult.error('Failed to send emergency alert');

    } catch (e) {
      print('❌ Emergency alert error: $e');
      return SafetyAlertResult.error(e.toString());
    }
  }

  /// 🛡️ SAFETY CHECK-IN - Call when user is safe
  static Future<SafetyAlertResult> sendSafetyCheckIn({
    required String status, // e.g., "Safe", "At home", "Arrived safely"
    String? customLocation,
  }) async {
    try {
      print('🛡️ SAFETY CHECK-IN: $status');

      String? userPlayerId = OneSignal.User.pushSubscription.id;
      if (userPlayerId == null) {
        return SafetyAlertResult.error('OneSignal not initialized');
      }

      if (_emergencyContacts.isEmpty) {
        return SafetyAlertResult.error('No emergency contacts configured');
      }

      String location = customLocation ?? await _getCurrentLocation();

      final response = await http.post(
        Uri.parse('$_baseUrl/sendSafetyCheckAlert'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userPlayerId': userPlayerId,
          'emergencyContacts': _emergencyContacts.map((c) => c.toJson()).toList(),
          'status': status,
          'location': location,
          'userName': _userName ?? 'Safety App User',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          print('✅ Safety check-in sent');
          return SafetyAlertResult.success('Safety check-in sent to contacts');
        }
      }

      return SafetyAlertResult.error('Failed to send safety check-in');

    } catch (e) {
      print('❌ Safety check-in error: $e');
      return SafetyAlertResult.error(e.toString());
    }
  }

  /// 📍 LOCATION SHARING - Share current location
  static Future<SafetyAlertResult> shareLocation({
    String? locationName,
    String? customLocation,
  }) async {
    try {
      print('📍 SHARING LOCATION');

      String? userPlayerId = OneSignal.User.pushSubscription.id;
      if (userPlayerId == null) {
        return SafetyAlertResult.error('OneSignal not initialized');
      }

      if (_emergencyContacts.isEmpty) {
        return SafetyAlertResult.error('No emergency contacts configured');
      }

      String location = customLocation ?? await _getCurrentLocation();

      final response = await http.post(
        Uri.parse('$_baseUrl/sendLocationUpdate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userPlayerId': userPlayerId,
          'emergencyContacts': _emergencyContacts.map((c) => c.toJson()).toList(),
          'location': location,
          'locationName': locationName,
          'userName': _userName ?? 'Safety App User',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          print('✅ Location shared');
          return SafetyAlertResult.success('Location shared with contacts');
        }
      }

      return SafetyAlertResult.error('Failed to share location');

    } catch (e) {
      print('❌ Location sharing error: $e');
      return SafetyAlertResult.error(e.toString());
    }
  }

  /// 🔋 LOW BATTERY ALERT - Automatic or manual
  static Future<SafetyAlertResult> sendLowBatteryAlert({
    int? customBatteryLevel,
    String? customLocation,
  }) async {
    try {
      print('🔋 LOW BATTERY ALERT');

      String? userPlayerId = OneSignal.User.pushSubscription.id;
      if (userPlayerId == null) {
        return SafetyAlertResult.error('OneSignal not initialized');
      }

      if (_emergencyContacts.isEmpty) {
        return SafetyAlertResult.error('No emergency contacts configured');
      }

      // Get battery level
      int batteryLevel = customBatteryLevel ?? 15; // Default to 15% if not provided
      try {
        Battery battery = Battery();
        batteryLevel = await battery.batteryLevel;
      } catch (e) {
        print('⚠️ Could not get battery level: $e');
      }

      String location = customLocation ?? await _getCurrentLocation();

      final response = await http.post(
        Uri.parse('$_baseUrl/sendLowBatteryAlert'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userPlayerId': userPlayerId,
          'emergencyContacts': _emergencyContacts.map((c) => c.toJson()).toList(),
          'batteryLevel': batteryLevel,
          'location': location,
          'userName': _userName ?? 'Safety App User',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          print('✅ Low battery alert sent');
          return SafetyAlertResult.success('Low battery alert sent to contacts');
        }
      }

      return SafetyAlertResult.error('Failed to send low battery alert');

    } catch (e) {
      print('❌ Low battery alert error: $e');
      return SafetyAlertResult.error(e.toString());
    }
  }

  /// 🚀 QUICK ACTIONS - Common combinations

  /// SOS - Emergency with immediate location sharing
  static Future<SafetyAlertResult> triggerSOS({String? customMessage}) async {
    print('🆘 SOS TRIGGERED - IMMEDIATE EMERGENCY');

    // Send both emergency alert and location sharing
    final emergencyResult = await sendEmergencyAlert(
      customMessage: customMessage ?? "🆘 SOS ACTIVATED - IMMEDIATE HELP NEEDED",
    );

    // Also share current location
    await shareLocation(locationName: "SOS Location");

    return emergencyResult;
  }

  /// Route Started - Notify contacts about journey
  static Future<SafetyAlertResult> notifyRouteStarted({
    required String destination,
    String? estimatedArrival,
  }) async {
    return await sendSafetyCheckIn(
      status: "Started journey to $destination${estimatedArrival != null ? ' - ETA: $estimatedArrival' : ''}",
    );
  }

  /// Route Completed - Notify safe arrival
  static Future<SafetyAlertResult> notifyRouteCompleted({
    required String destination,
  }) async {
    return await sendSafetyCheckIn(
      status: "Arrived safely at $destination",
    );
  }

  /// Panic Mode - Multiple alerts
  static Future<SafetyAlertResult> triggerPanicMode() async {
    print('🚨 PANIC MODE ACTIVATED');

    // Send emergency alert
    final result = await sendEmergencyAlert(
      customMessage: "🚨 PANIC MODE - MULTIPLE ALERTS SENT - CHECK IMMEDIATELY",
    );

    // Share location
    await shareLocation(locationName: "Panic Mode Location");

    // Send low battery alert if needed
    try {
      Battery battery = Battery();
      int batteryLevel = await battery.batteryLevel;
      if (batteryLevel <= 20) {
        await sendLowBatteryAlert();
      }
    } catch (e) {
      print('⚠️ Could not check battery in panic mode');
    }

    return result;
  }

  /// Get service status
  static Map<String, dynamic> getStatus() {
    return {
      'isInitialized': _userName != null,
      'userName': _userName,
      'emergencyContactsCount': _emergencyContacts.length,
      'oneSignalReady': OneSignal.User.pushSubscription.id != null,
      'playerId': OneSignal.User.pushSubscription.id,
    };
  }
}

/// Result class for safety alert operations
class SafetyAlertResult {
  final bool success;
  final String message;
  final String? error;

  SafetyAlertResult.success(this.message) : success = true, error = null;
  SafetyAlertResult.error(String errorMessage) : success = false, message = errorMessage, error = errorMessage;
}

/// Emergency Contact Model (same as before but moved here for easy access)
class EmergencyContact {
  final String name;
  final String phone;
  final String? playerId;
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

/// 🎯 Easy-to-use Widget for Safety Actions
class SafetyActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  final bool isLoading;

  const SafetyActionButton({
    Key? key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
      )
          : Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

/// 📱 Example Usage Widget - Show your colleague how to use the service
class SafetyServiceExample extends StatefulWidget {
  @override
  _SafetyServiceExampleState createState() => _SafetyServiceExampleState();
}

class _SafetyServiceExampleState extends State<SafetyServiceExample> {
  bool _isLoading = false;
  String? _lastResult;

  @override
  void initState() {
    super.initState();
    _initializeSafetyService();
  }

  Future<void> _initializeSafetyService() async {
    // Initialize with sample data
    await SafetyAlertService.initialize(
      userName: "Test User",
      emergencyContacts: [
        EmergencyContact(
          name: "Emergency Contact",
          phone: "+1234567890",
          playerId: OneSignal.User.pushSubscription.id, // Use current device for testing
        ),
      ],
    );
  }

  Future<void> _handleSafetyAction(Future<SafetyAlertResult> Function() action) async {
    setState(() {
      _isLoading = true;
    });

    final result = await action();

    setState(() {
      _isLoading = false;
      _lastResult = result.message;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.success ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('🛡️ Safety Service Demo'),
        backgroundColor: Colors.indigo,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Service Status
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('🛡️ Safety Service Status',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    SizedBox(height: 8),
                    ...SafetyAlertService.getStatus().entries.map((e) =>
                        Text('${e.key}: ${e.value}', style: TextStyle(fontSize: 12))
                    ).toList(),
                    if (_lastResult != null) ...[
                      SizedBox(height: 8),
                      Text('Last Result: $_lastResult',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // Quick Actions
            Text('🚨 Emergency Actions',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            SizedBox(height: 12),

            SafetyActionButton(
              label: 'SOS Emergency',
              icon: Icons.emergency,
              color: Colors.red,
              isLoading: _isLoading,
              onPressed: () => _handleSafetyAction(() => SafetyAlertService.triggerSOS()),
            ),

            SizedBox(height: 8),

            SafetyActionButton(
              label: 'Panic Mode',
              icon: Icons.warning,
              color: Colors.red[800]!,
              isLoading: _isLoading,
              onPressed: () => _handleSafetyAction(() => SafetyAlertService.triggerPanicMode()),
            ),

            SizedBox(height: 20),

            // Regular Actions
            Text('🛡️ Safety Actions',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            SizedBox(height: 12),

            SafetyActionButton(
              label: 'Check In Safe',
              icon: Icons.check_circle,
              color: Colors.green,
              isLoading: _isLoading,
              onPressed: () => _handleSafetyAction(() =>
                  SafetyAlertService.sendSafetyCheckIn(status: "I'm safe and sound")
              ),
            ),

            SizedBox(height: 8),

            SafetyActionButton(
              label: 'Share Location',
              icon: Icons.location_on,
              color: Colors.blue,
              isLoading: _isLoading,
              onPressed: () => _handleSafetyAction(() =>
                  SafetyAlertService.shareLocation(locationName: "Current Location")
              ),
            ),

            SizedBox(height: 8),

            SafetyActionButton(
              label: 'Low Battery Alert',
              icon: Icons.battery_alert,
              color: Colors.orange,
              isLoading: _isLoading,
              onPressed: () => _handleSafetyAction(() => SafetyAlertService.sendLowBatteryAlert()),
            ),

            SizedBox(height: 20),

            // Route Actions
            Text('🗺️ Journey Actions',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            SizedBox(height: 12),

            SafetyActionButton(
              label: 'Started Journey',
              icon: Icons.directions,
              color: Colors.purple,
              isLoading: _isLoading,
              onPressed: () => _handleSafetyAction(() =>
                  SafetyAlertService.notifyRouteStarted(
                      destination: "Office",
                      estimatedArrival: "30 minutes"
                  )
              ),
            ),

            SizedBox(height: 8),

            SafetyActionButton(
              label: 'Arrived Safely',
              icon: Icons.flag,
              color: Colors.teal,
              isLoading: _isLoading,
              onPressed: () => _handleSafetyAction(() =>
                  SafetyAlertService.notifyRouteCompleted(destination: "Office")
              ),
            ),

            SizedBox(height: 20),

            // Usage Instructions
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('💡 How to use in your code:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('// Emergency Alert\nSafetyAlertService.sendEmergencyAlert();',
                      style: TextStyle(fontFamily: 'monospace', fontSize: 11)),
                  SizedBox(height: 4),
                  Text('// Safety Check-In\nSafetyAlertService.sendSafetyCheckIn(status: "Safe");',
                      style: TextStyle(fontFamily: 'monospace', fontSize: 11)),
                  SizedBox(height: 4),
                  Text('// SOS (Quick Emergency)\nSafetyAlertService.triggerSOS();',
                      style: TextStyle(fontFamily: 'monospace', fontSize: 11)),
                ],
              ),
            ),

            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}