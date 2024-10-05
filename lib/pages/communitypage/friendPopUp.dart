import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FriendProfilePopup extends StatefulWidget {
  final String friendId; // Pass the friend's userId

  const FriendProfilePopup({required this.friendId});

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
    //fetch friends data from db to be displayed later on
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(widget.friendId).get();
      if (doc.exists) {
        var data = doc.data() as Map<String, dynamic>;
        setState(() {
          //add fields to retrieve
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
    }
  }

  // Fetch the recently played courts
  Future<void> _fetchCourtDetails(List<dynamic> lastCourts) async {
    try {
      // check if user has played in past
      if (lastCourts.isNotEmpty) {
        // First court
        if (lastCourts.isNotEmpty) {
          //find court in recent courts most recent, next is second most recent
          var firstCourtId = lastCourts[lastCourts.length - 1]['placeId'];
          // find court data by id in courts
          var firstCourtDoc = await FirebaseFirestore.instance.collection('basketball_courts').doc(firstCourtId).get();
          if (firstCourtDoc.exists) {
            //set variables to court data from db
            var courtData = firstCourtDoc.data() as Map<String, dynamic>;

            setState(() {
              firstCourtImageUrl = (courtData['imageUrls'] != null && courtData['imageUrls'].isNotEmpty)
                  ? courtData['imageUrls'][0]
                  : null;
              firstCourtName = courtData['name'];
            });
          }
        }

        // Same for Second court
        if (lastCourts.length > 1) {
          var secondCourtId = lastCourts[lastCourts.length - 2]['placeId'];
          var secondCourtDoc = await FirebaseFirestore.instance.collection('basketball_courts').doc(secondCourtId).get();
          if (secondCourtDoc.exists) {
            var courtData = secondCourtDoc.data() as Map<String, dynamic>;

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
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey[300], // Matching the background color
      title: Text(
        name ?? 'Profile des Freundes',
        style: const TextStyle(color: Colors.black, fontSize: 22),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey[500],
                backgroundImage: profileImageUrl != null && profileImageUrl!.isNotEmpty
                    ? NetworkImage(profileImageUrl!)
                    : null,
                child: profileImageUrl == null || profileImageUrl!.isEmpty
                    ? const Icon(Icons.person, size: 50, color: Colors.black)
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Name', name),
            _buildInfoRow('Alter', age),
            _buildInfoRow('Stadt', city),
            _buildInfoRow('Größe', height),
            _buildInfoRow('Position', position),
            _buildInfoRow('Skill Level', skillLevel),

            // Recently Played Section
            const SizedBox(height: 16),
            const Text(
              'Zuletzt gespielt',
              style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (firstCourtImageUrl == null && secondCourtImageUrl == null)
              const Text(
                'Dieser nutzer hat noch nicht gespielt.',
                style: TextStyle(color: Colors.black),
              )
            else if (firstCourtImageUrl != null && secondCourtImageUrl == null)
              Column(
                children: [
                  _buildCourtImageAndName(firstCourtImageUrl, firstCourtName),
                ],
              )
            else
              Column(
                children: [
                  _buildCourtImageAndName(firstCourtImageUrl, firstCourtName),
                  const SizedBox(height: 8),
                  _buildCourtImageAndName(secondCourtImageUrl, secondCourtName),
                ],
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text(
            'SCHLIEßEN',
            style: TextStyle(color: Colors.blue), // Teal button color
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
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Text(
            value ?? 'N/A',
            style: const TextStyle(color: Colors.black, fontSize: 16),
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
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
          ),
          child: imageUrl != null
              ? Image.network(imageUrl, fit: BoxFit.cover, width: 100, height: 100)
              : const Icon(Icons.location_on, color: Colors.black, size: 50),
        ),
        const SizedBox(height: 4),
        Text(
          courtName ?? 'Unbekannter Platz',
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}


