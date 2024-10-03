import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For formatting the date
import 'package:cloud_firestore/cloud_firestore.dart'; // For Firebase integration
import 'package:firebase_auth/firebase_auth.dart';  // Firebase Authentication
import 'package:intl/date_symbol_data_local.dart';  // For locale initialization

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
  MarkerDetailsPageState createState() => MarkerDetailsPageState();
}

class MarkerDetailsPageState extends State<MarkerDetailsPage> {
  late PageController _pageController;
  int _currentIndex = 0;
  late int _currentHour; // Ändere das zu currentHour
  Map<int, Map<String, dynamic>> _peoplePerHour = {};
  List<Map<String, dynamic>> _comments = [];
  bool _isClicked = false; // Initial state of the button (not clicked)

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);

    // Initialize the locale for the date in German (de)
    initializeDateFormatting('de', null).then((_) {
      setState(() {
        _fetchComments();
        _fetchPeoplePerHour();
      });
    });

    DateTime now = DateTime.now();
    int currentHour = now.hour;

    setState(() {
      _currentHour = currentHour;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

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
          const SnackBar(content: Text('Bitte gib deinen Namen im Profil ein')),
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

  Future<void> _showHourSelectionDialog() async {
    final List<int> hours = List.generate(25, (index) => index); // Bis 24 Uhr hinzufügen
    int startHour = _currentHour; // Startzeit auf die aktuelle Stunde setzen
    int endHour = startHour + 1;  // Standardmäßig eine Stunde später

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
                    items: hours.where((hour) => hour >= _currentHour && hour < 24).map((hour) { // Nur Stunden nach der aktuellen Stunde zulassen, außer 24
                      return DropdownMenuItem(
                        value: hour,
                        child: Text('$hour:00 Uhr'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        startHour = value!;
                        if (endHour <= startHour) {
                          endHour = startHour + 1; // Endzeit anpassen, falls sie vor der Startzeit liegt
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('Endzeit'),
                  DropdownButton<int>(
                    value: endHour,
                    items: hours.where((hour) => hour > startHour).map((hour) { // Endzeiten nur nach der Startzeit und inklusive 24 Uhr
                      return DropdownMenuItem(
                        value: hour,
                        child: Text(hour == 24 ? '24:00 Uhr' : '$hour:00 Uhr'), // 24 Uhr anzeigen
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

    // Get user profile from Firestore
    final DocumentReference userDocRef = firestore.collection('users').doc(user.uid);
    final DocumentSnapshot userProfile = await userDocRef.get();

    if (!userProfile.exists || userProfile.data() == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erstelle dein Profil')),
      );
      return;
    }

    final userData = userProfile.data() as Map<String, dynamic>;
    final String? username = userData['name'];

    // Check if username is null or empty
    if (username == null || username.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte gib deinen Namen im Profil ein')),
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
          const SnackBar(content: Text('Für diesen Zeitraum hast du dich bereits vollständig registriert.')),
        );
        return;
      }

      // Register only for hours the user is not yet registered for
      for (int hour = startHour; hour < endHour; hour++) {
        final hourData = todayCounts[hour.toString()] ?? {
          'count': 0,
          'users': <String>[],
        };

        final List<String> userIds = List<String>.from(hourData['users']);

        if (!userIds.contains(user.uid)) {
          userIds.add(user.uid);
          hourData['count'] = (hourData['count'] ?? 0) + 1;
          hourData['users'] = userIds;
          todayCounts[hour.toString()] = hourData;
        }
      }

      await placeDocRef.update({
        'peoplePerHour': {today: todayCounts}
      });

      // Update the user profile's last_courts field
      List<dynamic> lastCourts = userData['last_courts'] ?? [];

      // Check if the user is already registered for the current place and date
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
        _peoplePerHour = todayCounts.map((key, value) {
          return MapEntry(int.parse(key), {
            'count': value['count'] as int,
            'users': List<String>.from(value['users'] ?? []),
          });
        });
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

    // Verwende das deutsche Datumsformat mit einem Punkt nach dem Wochentag
    final currentDate = DateFormat('EEEE, dd. MMMM yyyy', 'de').format(DateTime.now());

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


  Future<void> _showUsersDialog(int hour) async {
    List<String> userIds = [];

    // Ensure the hour data is available and structured correctly
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
              maxWidth: MediaQuery.of(context).size.width * 0.6,  // Maximal 80% der Bildschirmbreite
              maxHeight: MediaQuery.of(context).size.height * 0.3, // Begrenze die Höhe des Dialogs auf 50% der Höhe
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0), // Gleiches Padding links und rechts
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween, // Platziere Überschrift oben und Button unten
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0), // Abstand von oben
                    child: Text(
                      'Angemeldete Nutzer für $hour:00 Uhr',
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width * 0.05,  // Dynamische Schriftgröße
                      ),
                      textAlign: TextAlign.center,  // Zentriere die Überschrift
                    ),
                  ),
                  Expanded(
                    child: userNames.isEmpty
                        ? const Center(
                      child: Text('Keine Nutzer angemeldet.'),
                    )
                        : Scrollbar(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: userNames.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(
                              userNames[index],
                              overflow: TextOverflow.ellipsis,  // Textüberlauf verhindern
                              style: TextStyle(fontSize: MediaQuery.of(context).size.width * 0.045),  // Schriftgröße anpassen
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0), // Abstand von unten
                    child: Center(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text(
                          'Schließen',
                          style: TextStyle(color: Colors.blue),  // Blau für bessere Sichtbarkeit
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
              // Ensure that _peoplePerHour contains a valid entry for this hour
              final Map<String, dynamic>? hourData = _peoplePerHour[index];

              // Safely access the count
              final int peopleCount = (hourData != null && hourData.containsKey('count'))
                  ? hourData['count'] as int
                  : 0;

              final bool isCurrentHour = index == _currentHour;

              return GestureDetector(
                onTap: () {
                  _showUsersDialog(index);  // Open dialog on circle tap
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '$index Uhr',
                        style: TextStyle(
                          fontSize: 16,
                          color: isCurrentHour ? Colors.orange : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Container(
                        width: screenWidth * 0.115,
                        height: screenWidth * 0.115,
                        decoration: BoxDecoration(
                          color: isCurrentHour ? Colors.orange : Colors.black,
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
      child: GestureDetector(
        onTap: _handleClick, // Trigger animation and show the dialog
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300), // Same duration for the animation
          curve: Curves.easeInOut, // Smooth animation curve
          width: _isClicked ? screenWidth * 0.55 : screenWidth * 0.6, // Adjust width during animation
          height: 50.0, // Height remains constant
          decoration: BoxDecoration(
            color: _isClicked ? Colors.orangeAccent : Colors.black, // Color changes during animation
            borderRadius: BorderRadius.circular(12), // Rounded corners
          ),
          alignment: Alignment.center, // Center the text and icon
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

  // Handling the button click animation
  void _handleClick() {
    setState(() {
      _isClicked = true;
    });

    // Reset animation after a short delay
    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        _isClicked = false;
      });
      _showHourSelectionDialog(); // Show the dialog after animation
    });
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
