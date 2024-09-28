import 'package:flutter/material.dart';

class InboxPage extends StatelessWidget {
  final List<String> friendInvites = ['Friend 1 sent a request', 'Friend 2 sent a request'];
  final List<String> groupInvites = ['Group 1 invite', 'Group 2 invite'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context); // Go back to the Community page
          },
        ),
        title: const Text('Inbox', style: TextStyle(color: Colors.white, fontSize: 22)),
      ),
      body: Container(
        color: Colors.grey[850],
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _buildInviteSection('Friend Invites', friendInvites),
            const SizedBox(height: 16.0),
            _buildInviteSection('Group Invites', groupInvites),
          ],
        ),
      ),
    );
  }

  // Widget to build invite sections
  Widget _buildInviteSection(String title, List<String> invites) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(color: Colors.white, thickness: 1),
          Column(
            children: invites.map((invite) {
              return ListTile(
                title: Text(invite, style: const TextStyle(color: Colors.white)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: () {
                        // Accept invite logic
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () {
                        // Decline invite logic
                      },
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}