import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FriendProfilePopup extends StatefulWidget {
  final String friendId; // Pass the friend's userId

  FriendProfilePopup({required this.friendId});

  @override
  _FriendProfilePopupState createState() => _FriendProfilePopupState();
}

class _FriendProfilePopupState extends State<FriendProfilePopup> {
  String? name;
  String? age;
  String? city;
  String? height;
  String? profileImageUrl;
  String? position;
  String? skillLevel;

  @override
  void initState() {
    super.initState();
    _loadFriendProfile();
  }

  // Fetch the friend's profile data from Firestore
  void _loadFriendProfile() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(widget.friendId).get();
      if (doc.exists) {
        var data = doc.data() as Map<String, dynamic>;
        setState(() {
          name = data['name'];
          age = data['age']?.toString();
          city = data['city'];
          height = data['height']?.toString();
          profileImageUrl = data['profileImage'];
          position = data['position'];
          skillLevel = data['skillLevel'];
        });
      }
    } catch (e) {
      print('Failed to load friend profile: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey[850], // Matching the background color
      title: Text(
        name ?? 'Friend Profile',
        style: TextStyle(color: Colors.white, fontSize: 22),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey[400],
                backgroundImage: profileImageUrl != null && profileImageUrl!.isNotEmpty
                    ? NetworkImage(profileImageUrl!)
                    : null,
                child: profileImageUrl == null || profileImageUrl!.isEmpty
                    ? Icon(Icons.person, size: 50, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Name', name),
            _buildInfoRow('Age', age),
            _buildInfoRow('City', city),
            _buildInfoRow('Height', height),
            _buildInfoRow('Position', position),
            _buildInfoRow('Skill Level', skillLevel),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text(
            'CLOSE',
            style: TextStyle(color: Colors.teal), // Teal button color
          ),
        ),
      ],
    );
  }

  // Helper function to build rows for profile information
  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Text(
            value ?? 'N/A',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

