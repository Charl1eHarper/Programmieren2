import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For formatting the date
import 'package:cloud_firestore/cloud_firestore.dart'; // For Firebase integration
import 'package:firebase_auth/firebase_auth.dart';  // Firebase Authentication

class MarkerDetailsPage extends StatefulWidget {
  final String markerName;
  final String markerAddress;
  final List<String> images;
  final String placeId;  // placeId wird übergeben

  const MarkerDetailsPage({
    super.key,
    required this.markerName,
    required this.markerAddress,
    required this.images,
    required this.placeId,  // placeId hinzugefügt
  });

  @override
  MarkerDetailsPageState createState() => MarkerDetailsPageState(); // Removed the underscore
}

class MarkerDetailsPageState extends State<MarkerDetailsPage> {
  late PageController _pageController;
  int _currentIndex = 0;
  late int _nextHour;
  Map<int, int> _peoplePerHour = {};  // peoplePerHour wird hier initialisiert
  List<Map<String, dynamic>> _comments = [];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    _fetchComments();
    _fetchPeoplePerHour(); // Neue Methode zum Abrufen von peoplePerHour

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

  // Fetch comments from Firebase for the marker using placeId (unverändert)
  Future<void> _fetchComments() async {
    final firestore = FirebaseFirestore.instance;
    final DocumentSnapshot placeDoc = await firestore.collection('basketball_courts').doc(widget.placeId).get();

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
        await firestore.collection('basketball_courts').doc(widget.placeId).update({
          'comments': [],
        });
      }
    }
  }

  // Neue Methode zum Abrufen von peoplePerHour aus Firestore
  Future<void> _fetchPeoplePerHour() async {
    final firestore = FirebaseFirestore.instance;
    final DocumentSnapshot placeDoc = await firestore.collection('basketball_courts').doc(widget.placeId).get();

    if (placeDoc.exists && placeDoc.data() != null) {
      final data = placeDoc.data() as Map<String, dynamic>;

      if (data.containsKey('peoplePerHour')) {
        final Map<String, dynamic> fetchedPeoplePerHour = data['peoplePerHour'];
        String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

        if (fetchedPeoplePerHour.containsKey(today)) {
          setState(() {
            _peoplePerHour = Map<int, int>.from(fetchedPeoplePerHour[today]);
          });
        }
      }
    }
  }

  // Kommentar-Funktion unverändert
  Future<void> _addComment(String commentText) async {
    final firestore = FirebaseFirestore.instance;
    final auth = FirebaseAuth.instance;

    // Get the current user
    final user = auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte logge dich ein')),
      );
      return;
    }

    // Get user profile from the Firestore 'users' collection
    final DocumentSnapshot userProfile = await firestore.collection('users').doc(user.uid).get();

    if (!userProfile.exists || userProfile.data() == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erstelle dein Profil')),
      );
      return;
    }

    final data = userProfile.data() as Map<String, dynamic>;

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
          'comments': FieldValue.arrayUnion([newComment]),
        });
      } else {
        await placeDocRef.set({
          'comments': [newComment],
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kommentar hinzugefügt')),
      );

      setState(() {
        _comments.add(newComment);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Hinzufügen des Kommentars: $e')),
      );
    }
  }

  // Dialog zum Schreiben eines Kommentars (unverändert)
  Future<void> _showCommentDialog() async {
    final TextEditingController commentController = TextEditingController();
    final auth = FirebaseAuth.instance;
    final user = auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte logge dich ein')),
      );
      return;
    }

    final firestore = FirebaseFirestore.instance;
    final DocumentSnapshot userProfile = await firestore.collection('users').doc(user.uid).get();

    if (userProfile.exists && userProfile.data() != null) {
      final userData = userProfile.data() as Map<String, dynamic>;

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

  // Neuer Dialog zur Auswahl des Zeitraums (Start- und Endzeit)
  Future<void> _showHourSelectionDialog() async {
    final List<int> hours = List.generate(24, (index) => index);
    int startHour = 12; // Default start time
    int endHour = 13;   // Default end time

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Wähle eine Zeitspanne'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Startzeit'),
                  DropdownButton<int>(
                    value: startHour,
                    items: hours.map((hour) {
                      return DropdownMenuItem(
                        value: hour,
                        child: Text('$hour:00 Uhr'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        startHour = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('Endzeit'),
                  DropdownButton<int>(
                    value: endHour,
                    items: hours.where((hour) => hour > startHour).map((hour) {
                      return DropdownMenuItem(
                        value: hour,
                        child: Text('$hour:00 Uhr'),
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
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Abbrechen'),
                ),
                TextButton(
                  onPressed: () {
                    _registerForTimeRange(startHour, endHour);  // Anmelde-Logik für Zeitspanne
                    Navigator.of(context).pop();
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

  // Anpassung der Registrierung für einen Zeitraum
  Future<void> _registerForTimeRange(int startHour, int endHour) async {
    final firestore = FirebaseFirestore.instance;
    final auth = FirebaseAuth.instance;
    final user = auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte logge dich ein')),
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

      final todayCounts = Map<String, int>.from(peoplePerHour[today] ?? {});

      for (int hour = startHour; hour < endHour; hour++) {
        todayCounts[hour.toString()] = (todayCounts[hour.toString()] ?? 0) + 1;
      }

      await placeDocRef.update({
        'peoplePerHour': {today: todayCounts}
      });

      setState(() {
        for (int hour = startHour; hour < endHour; hour++) {
          _peoplePerHour[hour] = todayCounts[hour.toString()] ?? 0;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Du hast dich erfolgreich für die Zeitspanne angemeldet.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler bei der Registrierung: $e')),
      );
    }
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
                  SizedBox(
                    height: screenHeight * 0.15,
                    child: _buildScrollableHourCircles(screenWidth),
                  ),
                  const SizedBox(height: 12),
                  _buildRegistrationSection(screenWidth),
                  const SizedBox(height: 12),
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
        child: const Icon(Icons.add_comment),
      ),
    );
  }

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
              final int peopleCount = _peoplePerHour[index] ?? 0;

              final bool isNextHour = index == _nextHour;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '$index Uhr',
                      style: TextStyle(
                        fontSize: 16,
                        color: isNextHour ? Colors.orange : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      width: screenWidth * 0.115,
                      height: screenWidth * 0.115,
                      decoration: BoxDecoration(
                        color: isNextHour ? Colors.orange : Colors.black,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '$peopleCount',
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
        width: screenWidth * 0.6,
        child: TextButton(
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all(Colors.black),
          ),
          onPressed: _showHourSelectionDialog, // Dialog für Zeitraum-Auswahl öffnen
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

  Widget _buildCommentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Kommentare', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 8),
        const Divider(
          color: Colors.black,
          thickness: 1,
          height: 1,
        ),
        const SizedBox(height: 8),
        _comments.isEmpty
            ? const Text('Noch keine Kommentare.')
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

  Widget _buildComment(String username, String comment, String profileImage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundImage: NetworkImage(profileImage),
                radius: 20,
              ),
              const SizedBox(width: 10),
              Text(username, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
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
