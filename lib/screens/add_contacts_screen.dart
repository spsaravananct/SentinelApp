import 'package:flutter/material.dart';

class AddContactsScreen extends StatelessWidget {
  const AddContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> contacts = [
      {"name": "Jane Cooper", "phone": "(270) 555-0117", "action": "add"},
      {"name": "Devon Lane", "phone": "(308) 555-0121", "action": "add"},
      {"name": "Darrell Steward", "phone": "(684) 555-0102", "action": "invite"},
      {"name": "Devon Lane", "phone": "(704) 555-0127", "action": "invite"},
      {"name": "Courtney Henry", "phone": "(505) 555-0125", "action": "add"},
      {"name": "Wade Warren", "phone": "(225) 555-0118", "action": "invite"},
      {"name": "Bessie Cooper", "phone": "(406) 555-0120", "action": "add"},
      {"name": "Robert Fox", "phone": "(480) 555-0103", "action": "invite"},
      {"name": "Jacob Jones", "phone": "(702) 555-0122", "action": "invite"},
      {"name": "Jenny Wilson", "phone": "(239) 555-0108", "action": "add"},
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: const Text(
          'My Contacts',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: const CircleAvatar(
              backgroundColor: Colors.red,
              radius: 20,
              child: Text(
                'SOS',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: const Color(0xFFF0F0F0),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: contacts.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final contact = contacts[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.grey[300],
                    child: Text(contact['name'][0]),
                  ),
                  title: Text(
                    contact['name'],
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    contact['phone'],
                    style: const TextStyle(color: Colors.grey),
                  ),
                  trailing: contact['action'] == "add"
                      ? Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue,
                    ),
                    padding: const EdgeInsets.all(8),
                    child: const Icon(Icons.add, color: Colors.white),
                  )
                      : const Text(
                    'Invite',
                    style: TextStyle(color: Colors.black),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
