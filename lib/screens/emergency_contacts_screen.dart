import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
// Import your ContactScreen here
import 'add_contacts_screen.dart';

class EmergencyContactsScreen extends StatefulWidget {
  @override
  _EmergencyContactsScreenState createState() => _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _emergencyContacts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchEmergencyContacts();
  }

  String getCurrentUserId() {
    final User? user = _auth.currentUser;
    return user?.uid ?? '';
  }

  Future<void> _fetchEmergencyContacts() async {
    try {
      String userId = getCurrentUserId();
      if (userId.isEmpty) return;

      DocumentSnapshot snapshot =
      await _firestore.collection('EmergencyContacts').doc(userId).get();

      if (snapshot.exists && snapshot.data() != null) {
        List<dynamic> contactsData = snapshot['contacts'] ?? [];
        setState(() {
          _emergencyContacts = contactsData.map((e) => {
            'user_id': e['user_id'],
            'contactName': e['contactName'],
            'phoneNumber': e['phoneNumber']
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching emergency contacts: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> saveEmergencyContact(
      String selectedUserId, String contactName, String phoneNumber) async {
    try {
      String userId = getCurrentUserId();
      if (userId.isEmpty) return;

      DocumentReference userRef =
      _firestore.collection('EmergencyContacts').doc(userId);

      await userRef.set({
        'contacts': FieldValue.arrayUnion([
          {
            'user_id': selectedUserId,
            'contactName': contactName,
            'phoneNumber': phoneNumber
          }
        ])
      }, SetOptions(merge: true));

      setState(() {
        _emergencyContacts.add({
          'user_id': selectedUserId,
          'contactName': contactName,
          'phoneNumber': phoneNumber
        });
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$contactName added to emergency contacts')),
      );
    } catch (e) {
      debugPrint('Error saving emergency contact: $e');
    }
  }

  Future<void> _removeEmergencyContact(String contactId) async {
    try {
      String userId = getCurrentUserId();
      if (userId.isEmpty) return;

      setState(() {
        _emergencyContacts.removeWhere((contact) => contact['user_id'] == contactId);
      });

      await _firestore.collection('EmergencyContacts').doc(userId).update({
        'contacts': FieldValue.arrayRemove([{'user_id': contactId}])
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Contact removed from emergency list')),
      );
    } catch (e) {
      debugPrint("Error removing emergency contact: $e");
    }
  }

  Future<void> _makeEmergencyCall(String phone) async {
    final Uri phoneUri = Uri.parse('tel:$phone');

    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not make call'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Emergency Contacts')),
      body: Column(
        children: [
          _isLoading
              ? const Expanded(child: Center(child: CircularProgressIndicator()))
              : Expanded(
            child: _emergencyContacts.isEmpty
                ? const Center(
              child: Text(
                'No emergency contacts added',
                style: TextStyle(color: Colors.grey),
              ),
            )
                : ListView.builder(
              itemCount: _emergencyContacts.length,
              itemBuilder: (context, index) {
                final contact = _emergencyContacts[index];
                return ListTile(
                  title: Text(contact['contactName']),
                  subtitle: Text(contact['phoneNumber']),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.call, color: Colors.green),
                        onPressed: () => _makeEmergencyCall(contact['phoneNumber']),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () =>
                            _removeEmergencyContact(contact['user_id']),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, size: 28),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ContactScreen()),
          );

          if (result != null || mounted) {
            _fetchEmergencyContacts();
          }
        },
      ),
    );
  }
}
