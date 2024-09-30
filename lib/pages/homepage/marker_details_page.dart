import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For formatting the date
import 'package:cloud_firestore/cloud_firestore.dart'; // For Firebase integration

class MarkerDetailsPage extends StatefulWidget {
  final String markerName;
  final String markerAddress;
  final List<String> images;
  final Map<int, int> peoplePerHour; // Placeholder for people count per hour

  const MarkerDetailsPage({
    super.key,
    required this.markerName,
    required this.markerAddress,
    required this.images,
    required this.peoplePerHour,
  });

  @override
  _MarkerDetailsPageState createState() => _MarkerDetailsPageState();
}

class _MarkerDetailsPageState extends State<MarkerDetailsPage> {
  late PageController _pageController;
  int _currentIndex = 0;
  late int _nextHour; // Variable to hold the next full hour
  List<Map<String, dynamic>> _comments = []; // List to store comments

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    _fetchComments(); // Fetch comments from Firebase

    // Get the current time and calculate the next full hour
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
    final DocumentSnapshot placeDoc = await firestore.collection('basketball_courts').doc(widget.markerName).get();

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
        await firestore.collection('basketball_courts').doc(widget.markerName).update({
          'comments': [],
        });
      }
    } else {
      print("Dokument existiert nicht oder ist leer");
    }
  }


  // Add new comment to Firebase
  // Add new comment to Firebase
  Future<void> _addComment(String commentText) async {
    final firestore = FirebaseFirestore.instance;
    final DocumentReference placeDocRef = firestore.collection('basketball_courts').doc(widget.markerName);

    final newComment = {
      'username': 'DummyUser', // Placeholder for the username
      'profile_image': 'https://via.placeholder.com/40', // Placeholder for the user image
      'comment': commentText,
      'timestamp': DateTime.now(), // Use local timestamp instead of serverTimestamp
    };

    try {
      final DocumentSnapshot placeDoc = await placeDocRef.get();
      if (placeDoc.exists) {
        // Add new comment to existing comments if comments field exists
        await placeDocRef.update({
          'comments': FieldValue.arrayUnion([newComment]), // Adds the comment to the existing array
        });
      } else {
        // Create new document with the comments array if it doesn't exist
        await placeDocRef.set({
          'comments': [newComment], // Initializes the comments field with the first comment
        });
      }

      // Refresh the comment section after adding
      setState(() {
        _comments.add(newComment);
      });

      print('Kommentar erfolgreich hinzugefügt');
    } catch (e) {
      print('Fehler beim Hinzufügen des Kommentars: $e');
    }
  }


  // Show a dialog to allow user to enter a new comment
  Future<void> _showCommentDialog() async {
    final TextEditingController _commentController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Schreibe einen Kommentar'),
          content: TextField(
            controller: _commentController,
            decoration: const InputDecoration(hintText: "Schreibe hier..."),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Abbrechen'),
            ),
            TextButton(
              onPressed: () {
                if (_commentController.text.isNotEmpty) {
                  _addComment(_commentController.text);
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
                  Text('$currentDate', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

                  // Button to add a new comment
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: _showCommentDialog,
                      icon: const Icon(Icons.add_comment),
                      label: const Text('Kommentar hinzufügen'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build the comment section
  Widget _buildCommentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Kommentare', style: TextStyle(fontWeight: FontWeight.bold)),
        _comments.isEmpty
            ? const Text('Noch keine Kommentare.') // Display this text if no comments
            : SizedBox(
          height: 200, // Limit height and make the comments scrollable
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _comments.length,
            itemBuilder: (context, index) {
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
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        children: [
          CircleAvatar(
            backgroundImage: NetworkImage(profileImage),
            radius: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(username, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(comment),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // The rest of the code remains the same...
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
      decoration: BoxDecoration(
        border: Border.all(color: Colors.orange, width: 2.0), // Orange border with 2.0 width
      ),
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
                      '${index} Uhr', // Display the hour
                      style: TextStyle(
                        fontSize: 14, // Slightly smaller font size for the hour label
                        color: isNextHour ? Colors.orange : Colors.black, // Mark the next hour in orange
                      ),
                    ),
                    const SizedBox(height: 4), // Adjusted space between text and circle
                    Container(
                      width: screenWidth * 0.1, // Dynamically set the width based on screen size
                      height: screenWidth * 0.1, // Same height as width for perfect circle
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
            backgroundColor: MaterialStateProperty.all(Colors.black),
          ),
          onPressed: () {
            // Placeholder action for user registration
            // In future, connect to database and allow user to select a time
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Wann bist du da?',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.add_circle, color: Colors.white),
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
