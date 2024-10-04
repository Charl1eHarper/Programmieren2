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

  // Variables to store recently played courts
  String? firstCourtImageUrl;
  String? secondCourtImageUrl;
  String? firstCourtName;
  String? secondCourtName;

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

          // Fetch recently played courts
          if (data['last_courts'] != null && data['last_courts'].length > 0) {
            List<dynamic> lastCourts = data['last_courts'];
            _fetchCourtDetails(lastCourts); // Fetch last two courts
          }
        });
      }
    } catch (e) {
      print('Failed to load friend profile: $e');
    }
  }

// Fetch the recently played courts
  Future<void> _fetchCourtDetails(List<dynamic> lastCourts) async {
    try {
      if (lastCourts.isNotEmpty) {
        // First court
        if (lastCourts.length > 0) {
          var firstCourtId = lastCourts[lastCourts.length - 1]['placeId'];
          var firstCourtDoc = await FirebaseFirestore.instance.collection('basketball_courts').doc(firstCourtId).get();
          if (firstCourtDoc.exists) {
            var courtData = firstCourtDoc.data() as Map<String, dynamic>;

            // Debugging - print court details
            print("First Court ID: $firstCourtId");
            print("First Court Data: ${courtData.toString()}");

            setState(() {
              firstCourtImageUrl = (courtData['imageUrls'] != null && courtData['imageUrls'].isNotEmpty)
                  ? courtData['imageUrls'][0]
                  : null;
              firstCourtName = courtData['name'];
            });
          }
        }

        // Second court
        if (lastCourts.length > 1) {
          var secondCourtId = lastCourts[lastCourts.length - 2]['placeId'];
          var secondCourtDoc = await FirebaseFirestore.instance.collection('basketball_courts').doc(secondCourtId).get();
          if (secondCourtDoc.exists) {
            var courtData = secondCourtDoc.data() as Map<String, dynamic>;

            // Debugging - print court details
            print("Second Court ID: $secondCourtId");
            print("Second Court Data: ${courtData.toString()}");

            setState(() {
              secondCourtImageUrl = (courtData['imageUrls'] != null && courtData['imageUrls'].isNotEmpty)
                  ? courtData['imageUrls'][0]
                  : null;
              secondCourtName = courtData['name'];
            });
          }
        }
      }
    } catch (e) {
      print('Failed to load court details: $e');
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

            // Recently Played Section
            const SizedBox(height: 16),
            Text(
              'Recently Played',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (firstCourtImageUrl != null || secondCourtImageUrl != null)
              Column(
                children: [
                  _buildCourtImageAndName(firstCourtImageUrl, firstCourtName),
                  const SizedBox(height: 8),
                  _buildCourtImageAndName(secondCourtImageUrl, secondCourtName),
                ],
              )
            else
              Text(
                'No recently played courts.',
                style: TextStyle(color: Colors.white70),
              ),
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

  // Helper to build rows for profile information
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

  // Helper to build court image and name in vertical layout
  Widget _buildCourtImageAndName(String? imageUrl, String? courtName) {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.grey[700],
            borderRadius: BorderRadius.circular(8),
          ),
          child: imageUrl != null
              ? Image.network(imageUrl, fit: BoxFit.cover, width: 100, height: 100)
              : Icon(Icons.location_on, color: Colors.white, size: 50),
        ),
        const SizedBox(height: 4),
        Text(
          courtName ?? 'Unknown Court',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

