import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Add this import
import 'dart:convert';

class ContactScreen extends StatefulWidget {
  @override
  _ContactScreenState createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  List<Contact> contacts = [];
  List<Contact> filteredContacts = [];
  List<Contact> addedUsers = [];
  Set<String> registeredPhoneNumbers = Set<String>();
  Map<String, String> phoneToUserIdMap = {}; // Add this to map phone numbers to user IDs
  String searchQuery = '';
  bool isLoadingRegisteredUsers = false;
  bool isLoadingContacts = false;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance; // Add this

  @override
  void initState() {
    super.initState();
    loadContacts();
    loadStoredData();
  }

  Future<void> loadStoredData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final addedData = prefs.getString('addedUsers');

      if (addedData != null) {
        final List<dynamic> decodedData = json.decode(addedData);
        addedUsers = decodedData
            .map((e) => Contact.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }

      setState(() {});
    } catch (e) {
      debugPrint('Error loading stored data: $e');
    }
  }

  Future<void> loadContacts() async {
    setState(() {
      isLoadingContacts = true;
    });

    try {
      PermissionStatus permission = await Permission.contacts.status;

      if (permission.isDenied || permission.isRestricted || permission.isLimited) {
        permission = await Permission.contacts.request();
      }

      if (permission.isGranted) {
        final allContacts = await FlutterContacts.getContacts(withProperties: true);
        setState(() {
          contacts = allContacts;
          filteredContacts = allContacts;
          isLoadingContacts = false;
        });

        // Load registered users after contacts are loaded
        await loadRegisteredUsersFromFirestore();
      } else {
        debugPrint('Contacts permission denied');
        setState(() {
          isLoadingContacts = false;
        });
        _showSnackBar('Contacts permission is required to show your contacts', Colors.red);
      }
    } catch (e) {
      debugPrint('Error loading contacts: $e');
      setState(() {
        isLoadingContacts = false;
      });
      _showSnackBar('Failed to load contacts', Colors.red);
    }
  }

  Future<void> loadRegisteredUsersFromFirestore() async {
    if (contacts.isEmpty) return;

    setState(() {
      isLoadingRegisteredUsers = true;
    });

    try {
      // Extract and clean all phone numbers from contacts
      List<String> contactPhones = [];
      for (Contact contact in contacts) {
        if (contact.phones.isNotEmpty) {
          for (Phone phone in contact.phones) {
            String cleanedPhone = _normalizePhoneNumber(phone.number);
            if (cleanedPhone.isNotEmpty && cleanedPhone.length >= 10) {
              contactPhones.add(cleanedPhone);
            }
          }
        }
      }

      if (contactPhones.isEmpty) {
        setState(() {
          isLoadingRegisteredUsers = false;
        });
        return;
      }

      // Remove duplicates
      contactPhones = contactPhones.toSet().toList();

      debugPrint('Checking ${contactPhones.length} phone numbers for registration');

      Set<String> foundNumbers = Set<String>();
      Map<String, String> tempPhoneToUserIdMap = {}; // Temporary map to build phone to user ID mapping

      // Firestore 'whereIn' has a limit of 10, so we need to batch the queries
      for (int i = 0; i < contactPhones.length; i += 10) {
        List<String> batch = contactPhones.skip(i).take(10).toList();

        try {
          QuerySnapshot querySnapshot = await _firestore
              .collection('Users')
              .where('phoneNumber', whereIn: batch)
              .get();

          for (QueryDocumentSnapshot doc in querySnapshot.docs) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            String phoneNumber = data['phoneNumber'] ?? '';
            String userId = doc.id; // Get the document ID as user ID

            if (phoneNumber.isNotEmpty) {
              String normalizedPhone = _normalizePhoneNumber(phoneNumber);
              if (normalizedPhone.isNotEmpty) {
                foundNumbers.add(normalizedPhone);
                tempPhoneToUserIdMap[normalizedPhone] = userId; // Map phone to user ID
                debugPrint('Found registered user: $normalizedPhone -> $userId');
              }
            }
          }
        } catch (e) {
          debugPrint('Error in batch query: $e');
        }
      }

      setState(() {
        registeredPhoneNumbers = foundNumbers;
        phoneToUserIdMap = tempPhoneToUserIdMap; // Update the phone to user ID mapping
        isLoadingRegisteredUsers = false;
      });

      debugPrint('Total registered users found: ${foundNumbers.length}');

    } catch (e) {
      debugPrint('Error loading registered users from Firestore: $e');
      setState(() {
        isLoadingRegisteredUsers = false;
      });
      _showSnackBar('Failed to check registered users', Colors.orange);
    }
  }

  // Normalize phone numbers to match the format used in your OTP system
  String _normalizePhoneNumber(String phone) {
    if (phone.isEmpty) return '';

    // Remove all non-digit characters
    String cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');

    // Handle different country code formats
    if (cleaned.startsWith('91') && cleaned.length == 12) {
      // Indian number with country code
      return '+91${cleaned.substring(2)}';
    } else if (cleaned.startsWith('1') && cleaned.length == 11) {
      // US/Canada number with country code
      return '+1${cleaned.substring(1)}';
    } else if (cleaned.length == 10) {
      // Assume it's a local number, add default country code (you can adjust this)
      return '+91$cleaned'; // Assuming Indian numbers as default
    } else if (cleaned.length > 10) {
      // Try to extract last 10 digits with appropriate country code
      String lastTen = cleaned.substring(cleaned.length - 10);
      return '+91$lastTen'; // Assuming Indian numbers as default
    }

    return cleaned.length >= 10 ? cleaned : '';
  }

  Future<void> saveAddedUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'addedUsers',
        json.encode(addedUsers.map((e) => e.toJson()).toList()),
      );
    } catch (e) {
      debugPrint('Error saving added users: $e');
    }
  }

  // New method to save emergency contact to Firestore
  Future<void> saveEmergencyContactToFirestore(Contact contact) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        _showSnackBar('User not authenticated', Colors.red);
        return;
      }

      String currentUserId = currentUser.uid;
      String contactPhone = _normalizePhoneNumber(contact.phones.first.number);
      String? contactUserId = phoneToUserIdMap[contactPhone];

      if (contactUserId == null) {
        debugPrint('Could not find user ID for phone: $contactPhone');
        _showSnackBar('Could not find user ID for this contact', Colors.red);
        return;
      }

      // Reference to the emergency contacts document
      DocumentReference docRef = _firestore
          .collection('EmergencyContacts')
          .doc(currentUserId);

      // Get the current document
      DocumentSnapshot docSnapshot = await docRef.get();

      Map<String, dynamic> contactData = {
        "user_id": contactUserId,
        "contactName": contact.displayName.isNotEmpty ? contact.displayName : 'Unknown',
        "phoneNumber": contactPhone,
      };

      if (docSnapshot.exists) {
        // Document exists, update the contacts array
        Map<String, dynamic> data = docSnapshot.data() as Map<String, dynamic>;
        List<dynamic> existingContacts = data['contacts'] ?? [];

        // Check if contact already exists
        bool contactExists = existingContacts.any((c) =>
        c['user_id'] == contactUserId || c['phoneNumber'] == contactPhone);

        if (!contactExists) {
          existingContacts.add(contactData);
          await docRef.update({
            'contacts': existingContacts,
          });
          debugPrint('Emergency contact added to existing document');
        } else {
          debugPrint('Contact already exists in emergency contacts');
        }
      } else {
        // Document doesn't exist, create new one
        await docRef.set({
          'user_id': currentUserId,
          'contacts': [contactData],
        });
        debugPrint('New emergency contacts document created');
      }

      _showSnackBar('Emergency contact saved successfully', Colors.green);

    } catch (e) {
      debugPrint('Error saving emergency contact to Firestore: $e');
      _showSnackBar('Failed to save emergency contact', Colors.red);
    }
  }

  // New method to remove emergency contact from Firestore
  Future<void> removeEmergencyContactFromFirestore(Contact contact) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        _showSnackBar('User not authenticated', Colors.red);
        return;
      }

      String currentUserId = currentUser.uid;
      String contactPhone = _normalizePhoneNumber(contact.phones.first.number);
      String? contactUserId = phoneToUserIdMap[contactPhone];

      // Reference to the emergency contacts document
      DocumentReference docRef = _firestore
          .collection('EmergencyContacts')
          .doc(currentUserId);

      // Get the current document
      DocumentSnapshot docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        Map<String, dynamic> data = docSnapshot.data() as Map<String, dynamic>;
        List<dynamic> existingContacts = data['contacts'] ?? [];

        // Remove the contact by user_id or phone number
        existingContacts.removeWhere((c) =>
        c['user_id'] == contactUserId || c['phoneNumber'] == contactPhone);

        await docRef.update({
          'contacts': existingContacts,
        });

        debugPrint('Emergency contact removed from Firestore');
        _showSnackBar('Emergency contact removed successfully', Colors.orange);
      }

    } catch (e) {
      debugPrint('Error removing emergency contact from Firestore: $e');
      _showSnackBar('Failed to remove emergency contact', Colors.red);
    }
  }

  void filterContacts(String query) {
    final results = contacts.where((contact) {
      final name = contact.displayName.toLowerCase();
      final phone = contact.phones.isNotEmpty ? contact.phones.first.number : '';
      return name.contains(query.toLowerCase()) || phone.contains(query);
    }).toList();

    setState(() {
      searchQuery = query;
      filteredContacts = results;
    });
  }

  void inviteUser(Contact contact) async {
    if (contact.phones.isEmpty) {
      _showSnackBar('No phone number available for this contact', Colors.red);
      return;
    }

    try {
      final Uri smsUri = Uri(
        scheme: 'sms',
        path: contact.phones.first.number,
        queryParameters: {
          'body': 'Hey! Check out this amazing app: https://example.com'
        },
      );

      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri, mode: LaunchMode.externalApplication);
      } else {
        _showSnackBar('Could not open SMS app', Colors.red);
      }
    } catch (e) {
      debugPrint('Error launching SMS: $e');
      _showSnackBar('Failed to send invitation', Colors.red);
    }
  }

  void addUser(Contact contact) async { // Modified to be async
    if (contact.phones.isEmpty) {
      _showSnackBar('No phone number available for this contact', Colors.red);
      return;
    }

    if (!isUserAdded(contact)) {
      setState(() {
        addedUsers.add(contact);
      });
      await saveAddedUsers();

      // Save to Firestore as emergency contact
      await saveEmergencyContactToFirestore(contact);

      _showSnackBar('${contact.displayName} added successfully', Colors.green);
    }
  }

  void removeUser(Contact contact) async { // Modified to be async
    setState(() {
      addedUsers.removeWhere((user) =>
      user.phones.isNotEmpty &&
          contact.phones.isNotEmpty &&
          _normalizePhoneNumber(user.phones.first.number) ==
              _normalizePhoneNumber(contact.phones.first.number)
      );
    });
    await saveAddedUsers();

    // Remove from Firestore
    await removeEmergencyContactFromFirestore(contact);

    _showSnackBar('${contact.displayName} removed', Colors.orange);
  }

  bool isUserAdded(Contact contact) {
    if (contact.phones.isEmpty) return false;

    String contactPhone = _normalizePhoneNumber(contact.phones.first.number);
    return addedUsers.any((user) =>
    user.phones.isNotEmpty &&
        _normalizePhoneNumber(user.phones.first.number) == contactPhone);
  }

  bool isUserRegistered(Contact contact) {
    if (contact.phones.isEmpty) return false;

    // Check all phone numbers of the contact
    for (Phone phone in contact.phones) {
      String normalizedPhone = _normalizePhoneNumber(phone.number);
      if (registeredPhoneNumbers.contains(normalizedPhone)) {
        return true;
      }
    }
    return false;
  }

  void _showSnackBar(String message, Color backgroundColor) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Widget _buildActionButton(Contact contact) {
    final registered = isUserRegistered(contact);
    final added = isUserAdded(contact);

    if (registered) {
      // User is registered - show Add/Added button
      if (added) {
        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF4285F4),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: () => removeUser(contact),
            icon: const Icon(Icons.check, color: Colors.white, size: 20),
            padding: EdgeInsets.zero,
          ),
        );
      } else {
        return TextButton(
          onPressed: () => addUser(contact),
          child: const Text(
            'Add',
            style: TextStyle(
              color: Color(0xFF4285F4),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        );
      }
    } else {
      // User is not registered - show Invite button
      return TextButton(
        onPressed: () => inviteUser(contact),
        child: const Text(
          'Invite',
          style: TextStyle(
            color: Colors.black54,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Colors.grey, width: 1),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black, size: 24),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'My Contacts',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: const CircleAvatar(
              backgroundColor: Colors.red,
              radius: 18,
              child: Text(
                'SOS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F8F8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              onChanged: filterContacts,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black,
              ),
              decoration: InputDecoration(
                hintText: 'Search contacts',
                hintStyle: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 16,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.grey[500],
                  size: 20,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
          ),

          // Loading indicators
          if (isLoadingContacts)
            Container(
              padding: const EdgeInsets.all(16),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Loading contacts...',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          else if (isLoadingRegisteredUsers)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Checking registered users...',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            ),

          // Contacts List
          Expanded(
            child: filteredContacts.isEmpty && !isLoadingContacts
                ? const Center(
              child: Text(
                'No contacts found',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            )
                : ListView.builder(
              itemCount: filteredContacts.length,
              itemBuilder: (context, index) {
                final contact = filteredContacts[index];
                final phone = contact.phones.isNotEmpty
                    ? contact.phones.first.number
                    : 'No phone number';

                return Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      // Profile Picture
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey[200],
                        ),
                        child: ClipOval(
                          child: contact.photo != null
                              ? Image.memory(
                            contact.photo!,
                            fit: BoxFit.cover,
                          )
                              : Icon(
                            Icons.person,
                            color: Colors.grey[600],
                            size: 25,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Contact Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              contact.displayName.isNotEmpty
                                  ? contact.displayName
                                  : 'Unknown',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              phone,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Action Button
                      if (contact.phones.isNotEmpty)
                        _buildActionButton(contact),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}