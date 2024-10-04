import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For formatting the date
import 'package:cloud_firestore/cloud_firestore.dart'; // For Firebase integration
import 'package:firebase_auth/firebase_auth.dart';  // Firebase Authentication
import 'package:intl/date_symbol_data_local.dart';  // For locale initialization

class MarkerDetailsPage extends StatefulWidget {
  final String markerName;
  final String markerAddress;
  final List<String> images;
  final String placeId;  // Unique place ID passed

  const MarkerDetailsPage({
    super.key,
    required this.markerName,
    required this.markerAddress,
    required this.images,
    required this.placeId,  // placeId passed
  });

  @override
  MarkerDetailsPageState createState() => MarkerDetailsPageState();
}

class MarkerDetailsPageState extends State<MarkerDetailsPage> {
  late PageController _pageController;
  int _currentIndex = 0;
  late int _currentHour; // Tracks the current hour
  Map<int, Map<String, dynamic>> _peoplePerHour = {}; // Stores people per hour data
  List<Map<String, dynamic>> _comments = []; // Holds user comments
  bool _isClicked = false; // Tracks if the button is clicked

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);

    // Initialize the locale for the date in German (de)
    initializeDateFormatting('de', null).then((_) {
      setState(() {
        _fetchComments(); // Load comments from Firestore
        _fetchPeoplePerHour(); // Load people per hour data
      });
    });

    DateTime now = DateTime.now();
    int currentHour = now.hour;

    setState(() {
      _currentHour = currentHour; // Set the current hour
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Fetch comments from Firebase
  Future<void> _fetchComments() async {
    final firestore = FirebaseFirestore.instance;
    final DocumentSnapshot placeDoc = await firestore.collection('basketball_courts').doc(widget.placeId).get();

    if (placeDoc.exists && placeDoc.data() != null) {
      final data = placeDoc.data() as Map<String, dynamic>;

      if (data.containsKey('comments')) {
        setState(() {
          _comments = List<Map<String, dynamic>>.from(data['comments']); // Populate comments list
        });
      } else {
        // Initialize empty comments if none exist
        setState(() {
          _comments = [];
        });
        await firestore.collection('basketball_courts').doc(widget.placeId).update({
          'comments': [],
        });
      }
    }
  }

  // Fetch people per hour data from Firestore
  Future<void> _fetchPeoplePerHour() async {
    final firestore = FirebaseFirestore.instance;
    final DocumentSnapshot placeDoc = await firestore.collection('basketball_courts').doc(widget.placeId).get();

    if (placeDoc.exists && placeDoc.data() != null) {
      final data = placeDoc.data() as Map<String, dynamic>;

      if (data.containsKey('peoplePerHour')) {
        final Map<String, dynamic> fetchedPeoplePerHour = Map<String, dynamic>.from(data['peoplePerHour']);
        String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

        if (fetchedPeoplePerHour.containsKey(today)) {
          final Map<String, dynamic> todayData = Map<String, dynamic>.from(fetchedPeoplePerHour[today]);
          setState(() {
            // Map the data to hour-based entries
            _peoplePerHour = todayData.map((key, value) {
              return MapEntry(int.parse(key), {
                'count': value['count'] as int,
                'users': List<String>.from(value['users'] ?? [])
              });
            });
          });
        }
      }
    }
  }

  // Add a comment to Firebase
  Future<void> _addComment(String commentText) async {
    final firestore = FirebaseFirestore.instance;
    final auth = FirebaseAuth.instance;

    // Get the current authenticated user
    final user = auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte logge dich ein')), // Prompt to log in
      );
      return;
    }

    // Fetch user profile from Firebase
    final DocumentSnapshot userProfile = await firestore.collection('users').doc(user.uid).get();

    if (!userProfile.exists || userProfile.data() == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erstelle dein Profil')), // Prompt to create a profile
      );
      return;
    }

    final data = userProfile.data() as Map<String, dynamic>;

    // Use username or default to 'Anonym'
    final String username = (data['name'] != null && data['name'].toString().trim().isNotEmpty)
        ? data['name']
        : 'Anonym';

    final String profileImage = data['profileImage'] ?? 'https://via.placeholder.com/40';

    final newComment = {
      'username': username,
      'profile_image': profileImage,
      'comment': commentText,
      'timestamp': DateTime.now(),
    };

    try {
      final DocumentReference placeDocRef = firestore.collection('basketball_courts').doc(widget.placeId);
      final DocumentSnapshot placeDoc = await placeDocRef.get();

      if (placeDoc.exists) {
        await placeDocRef.update({
          'comments': FieldValue.arrayUnion([newComment]), // Add new comment
        });
      } else {
        await placeDocRef.set({
          'comments': [newComment],
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kommentar hinzugefügt')), // Comment added successfully
      );

      setState(() {
        _comments.add(newComment); // Update comments list
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Hinzufügen des Kommentars: $e')), // Error handling
      );
    }
  }

  // Dialog to write a comment
  Future<void> _showCommentDialog() async {
    final TextEditingController commentController = TextEditingController();
    final auth = FirebaseAuth.instance;
    final user = auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte logge dich ein')), // Prompt to log in
      );
      return;
    }

    final firestore = FirebaseFirestore.instance;
    final DocumentSnapshot userProfile = await firestore.collection('users').doc(user.uid).get();

    if (userProfile.exists && userProfile.data() != null) {
      final userData = userProfile.data() as Map<String, dynamic>;

      if (userData['name'] == null || userData['name'].toString().trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bitte gib deinen Namen im Profil ein')), // Prompt to enter name
        );
        return;
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erstelle dein Profil')), // Prompt to create profile
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Schreibe einen Kommentar'), // Comment dialog title
          content: TextField(
            controller: commentController,
            decoration: const InputDecoration(hintText: "Schreibe hier..."), // Placeholder for input
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // Close dialog
              child: const Text('Abbrechen'),
            ),
            TextButton(
              onPressed: () {
                if (commentController.text.isNotEmpty) {
                  _addComment(commentController.text); // Add comment if input is not empty
                }
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text('Posten'),
            ),
          ],
        );
      },
    );
  }

  // Show dialog to select time range for registration
  Future<void> _showHourSelectionDialog() async {
    final List<int> hours = List.generate(25, (index) => index); // Generate hours from 0 to 24
    int startHour = _currentHour; // Set the start hour to the current hour
    int endHour = startHour + 1;  // Default end hour is one hour later

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Wähle eine Zeitspanne'), // Dialog title
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Startzeit'), // Start time label
                  DropdownButton<int>(
                    value: startHour,
                    items: hours.where((hour) => hour >= _currentHour && hour < 24).map((hour) { // Filter hours after current hour
                      return DropdownMenuItem(
                        value: hour,
                        child: Text('$hour:00 Uhr'), // Display hour
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        startHour = value!;
                        if (endHour <= startHour) {
                          endHour = startHour + 1; // Adjust end time if necessary
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('Endzeit'), // End time label
                  DropdownButton<int>(
                    value: endHour,
                    items: hours.where((hour) => hour > startHour).map((hour) { // Filter end hours after start hour
                      return DropdownMenuItem(
                        value: hour,
                        child: Text(hour == 24 ? '24:00 Uhr' : '$hour:00 Uhr'), // Handle 24-hour format
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        endHour = value!;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(), // Cancel action
                  child: const Text('Abbrechen'),
                ),
                TextButton(
                  onPressed: () {
                    _registerForTimeRange(startHour, endHour);  // Register for selected time range
                    Navigator.of(context).pop(); // Close dialog
                  },
                  child: const Text('Bestätigen'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Registration for a specific time range
  Future<void> _registerForTimeRange(int startHour, int endHour) async {
    final firestore = FirebaseFirestore.instance;
    final auth = FirebaseAuth.instance;
    final user = auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte logge dich ein')), // Prompt to log in
      );
      return;
    }

    // Get user profile from Firestore
    final DocumentReference userDocRef = firestore.collection('users').doc(user.uid);
    final DocumentSnapshot userProfile = await userDocRef.get();

    if (!userProfile.exists || userProfile.data() == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erstelle dein Profil')), // Prompt to create profile
      );
      return;
    }

    final userData = userProfile.data() as Map<String, dynamic>;
    final String? username = userData['name'];

    // Check if username is valid
    if (username == null || username.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte gib deinen Namen im Profil ein')), // Prompt to enter name
      );
      return;
    }

    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final DocumentReference placeDocRef = firestore.collection('basketball_courts').doc(widget.placeId);
      final DocumentSnapshot placeDoc = await placeDocRef.get();

      Map<String, dynamic> peoplePerHour = {};

      if (placeDoc.exists && placeDoc.data() != null) {
        final data = placeDoc.data() as Map<String, dynamic>;
        peoplePerHour = Map<String, dynamic>.from(data['peoplePerHour'] ?? {});
      }

      if (!peoplePerHour.containsKey(today)) {
        peoplePerHour[today] = {};
      }

      final todayCounts = Map<String, Map<String, dynamic>>.from(peoplePerHour[today] ?? {});

      bool alreadyRegisteredForAll = true;

      for (int hour = startHour; hour < endHour; hour++) {
        final hourData = todayCounts[hour.toString()] ?? {
          'count': 0,
          'users': <String>[],
        };

        final List<String> userIds = List<String>.from(hourData['users']);

        if (!userIds.contains(user.uid)) {
          alreadyRegisteredForAll = false;
          break;
        }
      }

      if (alreadyRegisteredForAll) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Für diesen Zeitraum hast du dich bereits vollständig registriert.')), // Already registered for this time
        );
        return;
      }

      // Register for the hours the user is not yet registered
      for (int hour = startHour; hour < endHour; hour++) {
        final hourData = todayCounts[hour.toString()] ?? {
          'count': 0,
          'users': <String>[],
        };

        final List<String> userIds = List<String>.from(hourData['users']);

        if (!userIds.contains(user.uid)) {
          userIds.add(user.uid); // Add user to the list
          hourData['count'] = (hourData['count'] ?? 0) + 1;
          hourData['users'] = userIds;
          todayCounts[hour.toString()] = hourData;
        }
      }

      await placeDocRef.update({
        'peoplePerHour': {today: todayCounts}
      });

      // Update user profile with last courts
      List<dynamic> lastCourts = userData['last_courts'] ?? [];

      bool alreadyRegisteredForPlaceToday = lastCourts.any((court) {
        return court['placeId'] == widget.placeId && court['date'] == today;
      });

      if (!alreadyRegisteredForPlaceToday) {
        lastCourts.add({
          'placeId': widget.placeId,
          'date': today,
        });

        await userDocRef.update({
          'last_courts': lastCourts,
        });
      }

      setState(() {
        // Update people per hour data
        _peoplePerHour = todayCounts.map((key, value) {
          return MapEntry(int.parse(key), {
            'count': value['count'] as int,
            'users': List<String>.from(value['users'] ?? []),
          });
        });
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Du hast dich erfolgreich für die Zeitspanne angemeldet.')), // Registration success
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler bei der Registrierung: $e')), // Error handling
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // Format the current date in German
    final currentDate = DateFormat('EEEE, dd. MMMM yyyy', 'de').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(widget.markerName, style: const TextStyle(color: Colors.white)), // Display the marker name
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context); // Navigate back
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display image carousel at the top
            SizedBox(
              height: screenHeight * 0.30,
              child: _buildImageCarousel(),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                widget.markerAddress, // Display the marker address
                style: const TextStyle(fontSize: 17),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(currentDate, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), // Display current date
                  const SizedBox(height: 8),
                  SizedBox(
                    height: screenHeight * 0.15,
                    child: _buildScrollableHourCircles(screenWidth), // Show hour circles
                  ),
                  const SizedBox(height: 12),
                  _buildRegistrationSection(screenWidth), // Show registration section
                  const SizedBox(height: 12),
                  _buildCommentSection(), // Display comments
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCommentDialog, // Show dialog to add a comment
        tooltip: 'Kommentar hinzufügen',
        child: const Icon(Icons.add_comment),
      ),
    );
  }

  // Show dialog with users registered for the specific hour
  Future<void> _showUsersDialog(int hour) async {
    List<String> userIds = [];

    // Get the list of users for the hour
    if (_peoplePerHour.containsKey(hour)) {
      final hourData = _peoplePerHour[hour];

      if (hourData != null && hourData.containsKey('users')) {
        userIds = List<String>.from(hourData['users'] ?? []);
      }
    }

    // Fetch usernames from Firestore based on userIds
    List<String> userNames = [];
    for (String userId in userIds) {
      final DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (userDoc.exists && userDoc.data() != null) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final String userName = userData['name'] ?? 'Unbekannt';
        userNames.add(userName);
      } else {
        userNames.add('Unbekannt');
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.6,  // Limit the dialog width
              maxHeight: MediaQuery.of(context).size.height * 0.3, // Limit the dialog height
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0), // Equal padding on both sides
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween, // Align title and button
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0), // Add space at the top
                    child: Text(
                      'Angemeldete Nutzer für $hour:00 Uhr', // Show registered users for the hour
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width * 0.05,  // Dynamic font size
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: userNames.isEmpty
                        ? const Center(
                      child: Text('Keine Nutzer angemeldet.'), // Display message if no users registered
                    )
                        : Scrollbar(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: userNames.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(
                              userNames[index],
                              overflow: TextOverflow.ellipsis,  // Prevent text overflow
                              style: TextStyle(fontSize: MediaQuery.of(context).size.width * 0.045),  // Adjust font size
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0), // Space at the bottom
                    child: Center(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // Close dialog
                        },
                        child: const Text(
                          'Schließen',
                          style: TextStyle(color: Colors.blue),  // Use blue color for visibility
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Build the hour circles showing people count
  Widget _buildScrollableHourCircles(double screenWidth) {
    return Container(
      decoration: const BoxDecoration(),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(24, (index) {
              // Safely access people count for each hour
              final Map<String, dynamic>? hourData = _peoplePerHour[index];
              final int peopleCount = (hourData != null && hourData.containsKey('count'))
                  ? hourData['count'] as int
                  : 0;

              final bool isCurrentHour = index == _currentHour; // Highlight current hour

              return GestureDetector(
                onTap: () {
                  _showUsersDialog(index);  // Show users dialog on circle tap
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '$index Uhr', // Display hour
                        style: TextStyle(
                          fontSize: 16,
                          color: isCurrentHour ? Colors.orange : Colors.black, // Highlight current hour
                        ),
                      ),
                      const SizedBox(height: 5),
                      Container(
                        width: screenWidth * 0.115,
                        height: screenWidth * 0.115,
                        decoration: BoxDecoration(
                          color: isCurrentHour ? Colors.orange : Colors.black, // Highlight current hour
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '$peopleCount', // Show people count
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
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  // Build the registration button
  Widget _buildRegistrationSection(double screenWidth) {
    return Center(
      child: GestureDetector(
        onTap: _handleClick, // Trigger button animation and show dialog
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300), // Animation duration
          curve: Curves.easeInOut,
          width: _isClicked ? screenWidth * 0.55 : screenWidth * 0.6, // Animate width change
          height: 50.0,
          decoration: BoxDecoration(
            color: _isClicked ? Colors.orangeAccent : Colors.black, // Animate color change
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Wann bist du da?', // Button label
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
              SizedBox(width: 8),
              Icon(Icons.add_circle, color: Colors.white), // Button icon
            ],
          ),
        ),
      ),
    );
  }

  // Handle button click with animation
  void _handleClick() {
    setState(() {
      _isClicked = true;
    });

    // Reset animation after a short delay
    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        _isClicked = false;
      });
      _showHourSelectionDialog(); // Show dialog after animation
    });
  }

  // Build the comment section
  Widget _buildCommentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Kommentare', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), // Comments title
        const SizedBox(height: 8),
        const Divider(
          color: Colors.black,
          thickness: 1,
          height: 1,
        ),
        const SizedBox(height: 8),
        _comments.isEmpty
            ? const Text('Noch keine Kommentare.') // Display message if no comments
            : SizedBox(
          height: 200,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _comments.length + 1,
            itemBuilder: (context, index) {
              if (index == _comments.length) {
                return const SizedBox(height: 60);
              }
              final comment = _comments[index];
              return _buildComment(
                comment['username'] ?? 'Anonym', // Display comment username
                comment['comment'] ?? '', // Display comment text
                comment['profile_image'] ?? 'https://via.placeholder.com/40', // Display profile image
              );
            },
          ),
        ),
      ],
    );
  }

  // Build each comment
  Widget _buildComment(String username, String comment, String profileImage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundImage: NetworkImage(profileImage), // Display user's profile image
                radius: 20,
              ),
              const SizedBox(width: 10),
              Text(username, style: const TextStyle(fontWeight: FontWeight.bold)), // Display user's name
            ],
          ),
          const SizedBox(height: 8),
          Text(
            comment, // Display comment text
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  // Build the image carousel
  Widget _buildImageCarousel() {
    return Stack(
      alignment: Alignment.center,
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: widget.images.length,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index; // Update current index on page change
            });
          },
          itemBuilder: (context, index) {
            return Image.network(
              widget.images[index], // Display each image
              width: double.infinity,
              fit: BoxFit.cover,
            );
          },
        ),
        Positioned(
          left: 16,
          child: _buildArrowButton(
            icon: Icons.arrow_back, // Previous arrow button
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
            icon: Icons.arrow_forward, // Next arrow button
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

  // Build arrow button for image navigation
  Widget _buildArrowButton({required IconData icon, required VoidCallback onPressed}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.5), // Semi-transparent background for button
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white), // Display arrow icon
        onPressed: onPressed, // Define action for button
      ),
    );
  }
}
