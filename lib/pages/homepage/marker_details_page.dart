import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For formatting the date
import 'package:cloud_firestore/cloud_firestore.dart'; // For Firebase integration
import 'package:firebase_auth/firebase_auth.dart';  // Firebase Authentication

class MarkerDetailsPage extends StatefulWidget {
  final String markerName;
  final String markerAddress;
  final List<String> images;
  final Map<int, int> peoplePerHour;
  final String placeId;  // Neu: placeId wird übergeben

  const MarkerDetailsPage({
    super.key,
    required this.markerName,
    required this.markerAddress,
    required this.images,
    required this.peoplePerHour,
    required this.placeId,  // placeId hinzugefügt
  });

  @override
  MarkerDetailsPageState createState() => MarkerDetailsPageState(); // Removed the underscore
}

// Renamed _MarkerDetailsPageState to MarkerDetailsPageState
class MarkerDetailsPageState extends State<MarkerDetailsPage> {
  late PageController _pageController;
  int _currentIndex = 0;
  late int _nextHour;
  List<Map<String, dynamic>> _comments = [];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    _fetchComments();

    DateTime now = DateTime.now();
    int currentHour = now.hour;
    int currentMinute = now.minute;

    setState(() {
      _nextHour = (currentMinute > 0) ? (currentHour + 1) % 24 : currentHour;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Fetch comments from Firebase for the marker using placeId
  Future<void> _fetchComments() async {
    final firestore = FirebaseFirestore.instance;
    final DocumentSnapshot placeDoc = await firestore.collection('basketball_courts').doc(widget.placeId).get(); // Verwende placeId

    if (placeDoc.exists && placeDoc.data() != null) {
      final data = placeDoc.data() as Map<String, dynamic>;

      if (data.containsKey('comments')) {
        setState(() {
          _comments = List<Map<String, dynamic>>.from(data['comments']);
        });
      } else {
        setState(() {
          _comments = [];
        });
        await firestore.collection('basketball_courts').doc(widget.placeId).update({ // Verwende placeId
          'comments': [],
        });
      }
    }
  }

// Add new comment to Firebase
  Future<void> _addComment(String commentText) async {
    final firestore = FirebaseFirestore.instance;
    final auth = FirebaseAuth.instance;

    // Get the current user
    final user = auth.currentUser;

    // Check if the user is logged in
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte logge dich ein')),
      );
      return;
    }

    // Get user profile from the Firestore 'users' collection
    final DocumentSnapshot userProfile = await firestore.collection('users').doc(user.uid).get();

    // Check if the profile exists and is complete
    if (!userProfile.exists || userProfile.data() == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erstelle dein Profil')),
      );
      return;
    }

    final data = userProfile.data() as Map<String, dynamic>;

    // Check if the username is valid
    final String username = (data['name'] != null && data['name'].toString().trim().isNotEmpty)
        ? data['name']
        : 'Anonym'; // Fallback to 'Anonym' if no valid name is provided

    // Fallback to placeholder profile image if not present
    final String profileImage = data['profileImage'] ?? 'https://via.placeholder.com/40'; // Default placeholder image

    // Prepare the new comment
    final newComment = {
      'username': username,
      'profile_image': profileImage,
      'comment': commentText,
      'timestamp': DateTime.now(),
    };

    try {
      // Update the comments in the basketball_courts collection
      final DocumentReference placeDocRef = firestore.collection('basketball_courts').doc(widget.placeId);
      final DocumentSnapshot placeDoc = await placeDocRef.get();

      if (placeDoc.exists) {
        await placeDocRef.update({
          'comments': FieldValue.arrayUnion([newComment]),
        });
      } else {
        await placeDocRef.set({
          'comments': [newComment],
        });
      }

      setState(() {
        _comments.add(newComment);
      });
    } catch (e) {
      // Handle error if needed
    }
  }

// Dialog zum Schreiben eines Kommentars
  Future<void> _showCommentDialog() async {
    final TextEditingController commentController = TextEditingController();
    final auth = FirebaseAuth.instance;
    final user = auth.currentUser;

    // Check if the user is logged in
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte logge dich ein')),
      );
      return;
    }

    // Get user profile from Firestore
    final firestore = FirebaseFirestore.instance;
    final DocumentSnapshot userProfile = await firestore.collection('users').doc(user.uid).get();

    // Check if the profile is complete
    if (userProfile.exists && userProfile.data() != null) {
      final userData = userProfile.data() as Map<String, dynamic>;

      // Check if the user has a valid name
      if (userData['name'] == null || userData['name'].toString().trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bitte gib deinen Namen ein')),
        );
        return;
      }

    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erstelle dein Profil')),
      );
      return;
    }

    // If everything is valid, allow user to post a comment
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Schreibe einen Kommentar'),
          content: TextField(
            controller: commentController,
            decoration: const InputDecoration(hintText: "Schreibe hier..."),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Abbrechen'),
            ),
            TextButton(
              onPressed: () {
                if (commentController.text.isNotEmpty) {
                  _addComment(commentController.text);
                }
                Navigator.of(context).pop();
              },
              child: const Text('Posten'),
            ),
          ],
        );
      },
    );
  }




  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final currentDate = DateFormat('EEEE, dd MMM yyyy').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(widget.markerName, style: const TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image carousel (unchanged)
            SizedBox(
              height: screenHeight * 0.30,
              child: _buildImageCarousel(),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                widget.markerAddress,
                style: const TextStyle(fontSize: 17),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(currentDate, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),

                  // Section for "Anzahl an Leuten" (People count for each hour)
                  SizedBox(
                    height: screenHeight * 0.15,  // Reduced height for circles
                    child: _buildScrollableHourCircles(screenWidth),
                  ),
                  const SizedBox(height: 12),

                  // Registration button
                  _buildRegistrationSection(screenWidth),

                  const SizedBox(height: 12),

                  // Comment section
                  _buildCommentSection(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCommentDialog,
        tooltip: 'Kommentar hinzufügen',
        child: const Icon(Icons.add_comment),  // Move 'child' to the last position
      ),
    );
  }

  // Build the comment section
  Widget _buildCommentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Kommentare', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 8), // Space between the title and the divider
        const Divider( // Add a thin black line below the title
          color: Colors.black, // Line color
          thickness: 1, // Line thickness
          height: 1, // Space taken by the divider
        ),
        const SizedBox(height: 8), // Space between the divider and the comments
        _comments.isEmpty
            ? const Text('Noch keine Kommentare.') // Display this text if no comments
            : SizedBox(
          height: 200, // Limit height and make the comments scrollable
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _comments.length + 1, // Increase itemCount by 1 for padding
            itemBuilder: (context, index) {
              if (index == _comments.length) {
                // Add extra padding at the bottom of the list
                return const SizedBox(height: 60);  // Adjust the height of the padding
              }
              final comment = _comments[index];
              return _buildComment(
                comment['username'] ?? 'Anonym',
                comment['comment'] ?? '',
                comment['profile_image'] ?? 'https://via.placeholder.com/40',
              );
            },
          ),
        ),
      ],
    );
  }



  // Build a single comment widget
  Widget _buildComment(String username, String comment, String profileImage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),  // Add vertical padding between comments
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,  // Align all items to the start (left)
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundImage: NetworkImage(profileImage),  // Profile image
                radius: 20,
              ),
              const SizedBox(width: 10),  // Space between image and username
              Text(username, style: const TextStyle(fontWeight: FontWeight.bold)),  // Username
            ],
          ),
          const SizedBox(height: 8),  // Space between username and comment
          Text(
            comment,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }


  Widget _buildImageCarousel() {
    return Stack(
      alignment: Alignment.center,
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: widget.images.length,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          itemBuilder: (context, index) {
            return Image.network(
              widget.images[index],
              width: double.infinity,
              fit: BoxFit.cover,
            );
          },
        ),
        Positioned(
          left: 16,
          child: _buildArrowButton(
            icon: Icons.arrow_back,
            onPressed: () {
              if (_currentIndex > 0) {
                _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
            },
          ),
        ),
        Positioned(
          right: 16,
          child: _buildArrowButton(
            icon: Icons.arrow_forward,
            onPressed: () {
              if (_currentIndex < widget.images.length - 1) {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildScrollableHourCircles(double screenWidth) {
    return Container(
      // Remove the border from the decoration
      decoration: const BoxDecoration(), // No border now
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal, // Horizontal scrolling
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0), // Vertical padding for better alignment
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center, // Center items vertically
            children: List.generate(24, (index) {
              final int peopleCount = widget.peoplePerHour[index] ?? 0; // Default to 0 if no data

              // Determine if this is the next hour, and set the color accordingly
              final bool isNextHour = index == _nextHour;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0), // Horizontal padding for spacing
                child: Column(
                  mainAxisSize: MainAxisSize.min, // Minimize vertical space
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '$index Uhr', // Display the hour
                      style: TextStyle(
                        fontSize: 16, // Slightly smaller font size for the hour label
                        color: isNextHour ? Colors.orange : Colors.black, // Mark the next hour in orange
                      ),
                    ),
                    const SizedBox(height: 5), // Adjusted space between text and circle
                    Container(
                      width: screenWidth * 0.115, // Dynamically set the width based on screen size
                      height: screenWidth * 0.115, // Same height as width for perfect circle
                      decoration: BoxDecoration(
                        color: isNextHour ? Colors.orange : Colors.black, // Change circle color for the next hour
                        shape: BoxShape.circle, // Make it a circle
                      ),
                      child: Center(
                        child: Text(
                          '$peopleCount', // Display the people count
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    );
  }


  Widget _buildRegistrationSection(double screenWidth) {
    return Center(
      child: SizedBox(
        width: screenWidth * 0.6,  // Full-width button
        child: TextButton(
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all(Colors.black),
          ),
          onPressed: () {
            // Placeholder action for user registration
            // In future, connect to database and allow user to select a time
          },
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Wann bist du da?',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
              SizedBox(width: 8),
              Icon(Icons.add_circle, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArrowButton({required IconData icon, required VoidCallback onPressed}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.5),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onPressed,
      ),
    );
  }
}
