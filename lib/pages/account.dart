import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io'; // For File handling

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  _AccountPageState createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController heightController = TextEditingController();

  User? user = FirebaseAuth.instance.currentUser;
  File? _profileImage;
  String? _profileImageUrl;

  String? selectedPosition;
  String? selectedSkillLevel;

  final List<String> positions = ['PG', 'SG', 'SF', 'PF', 'C'];
  final List<String> skillLevels = ['Anfänger', 'Amateur', 'Fortgeschritten', 'Experte', 'Pro']; // Updated skill levels

  // Variables to store recently played courts
  String? firstCourtImageUrl;
  String? secondCourtImageUrl;
  String? firstCourtName;
  String? secondCourtName;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  void _loadUserProfile() async {
    if (user != null) {
      try {
        DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
        if (doc.exists) {
          var data = doc.data() as Map<String, dynamic>;
          setState(() {
            nameController.text = data['name'] ?? '';
            ageController.text = data['age']?.toString() ?? '';
            cityController.text = data['city'] ?? '';
            heightController.text = data['height']?.toString() ?? '';
            selectedPosition = positions.contains(data['position']) ? data['position'] : null;
            selectedSkillLevel = skillLevels.contains(data['skillLevel']) ? data['skillLevel'] : null;
            _profileImageUrl = data['profileImage'] ?? '';

            // Fetch the last two played courts
            if (data['last_courts'] != null && data['last_courts'].length > 0) {
              List<dynamic> lastCourts = data['last_courts'];
              _fetchCourtDetails(lastCourts); // Fetch last two courts
            }
          });
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Profil konnte nicht geladen werden: $e")),
        );
      }
    }
  }

  Future<void> _fetchCourtDetails(List<dynamic> lastCourts) async {
    try {
      if (lastCourts.isNotEmpty) {
        // First court
        if (lastCourts.isNotEmpty) {
          var firstCourtId = lastCourts[lastCourts.length - 1]['placeId'];
          var firstCourtDoc = await FirebaseFirestore.instance.collection('basketball_courts').doc(firstCourtId).get();
          if (firstCourtDoc.exists) {
            var courtData = firstCourtDoc.data() as Map<String, dynamic>;

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Platz Details konnten nicht geladen werden: $e")),
      );
    }
  }

  void _saveUserProfile() async {
    if (user != null) {
      int age = int.tryParse(ageController.text) ?? -1;
      double height = double.tryParse(heightController.text) ?? 0.0;

      if (age < 0) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Alter kann nicht weniger als 0 sein")));
        return;
      }

      if (height <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Größe muss in cm angegeben werden")));
        return;
      }

      try {
        await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
          'name': nameController.text,
          'age': age,
          'city': cityController.text,
          'height': height,
          'position': selectedPosition ?? positions[0],
          'skillLevel': selectedSkillLevel ?? skillLevels[0],
          'profileImage': _profileImageUrl ?? '',
        }, SetOptions(merge: true));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profil gespeichert")),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Pofil konnte nicht gespeichert werden: $e")),
        );
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
      _uploadProfileImage();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kein Bild ausgewählt!")));
    }
  }

  Future<void> _uploadProfileImage() async {
    if (_profileImage == null || user == null) return;

    try {
      final storageRef = FirebaseStorage.instance.ref().child('profile_images/${user!.uid}.jpg');
      UploadTask uploadTask = storageRef.putFile(_profileImage!);
      TaskSnapshot snapshot = await uploadTask.whenComplete(() {});
      String downloadUrl = await snapshot.ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
        'profileImage': downloadUrl,
      }, SetOptions(merge: true));

      setState(() {
        _profileImageUrl = downloadUrl;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profilbild gespeichert")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Profilbildspeicherfehler: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text('Profil bearbeiten', style: TextStyle(color: Colors.black, fontSize: 22)),
        actions: [
          IconButton(
            icon: const Icon(Icons.save, color: Colors.black),
            onPressed: _saveUserProfile,
          ),
        ],
      ),
      body: Container(
        color: Colors.grey[300],
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Center(
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 100,
                              backgroundColor: Colors.grey[500],
                              backgroundImage: _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                                  ? NetworkImage(_profileImageUrl!)
                                  : null,
                              child: _profileImageUrl == null || _profileImageUrl!.isEmpty
                                  ? const Icon(Icons.person, size: 100, color: Colors.black)
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () {
                                  _showImagePickerOptions();
                                },
                                child: const CircleAvatar(
                                  backgroundColor: Colors.black,
                                  radius: 28,
                                  child: Icon(Icons.camera_alt, color: Colors.white, size: 28),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Profile form fields
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  _buildTextField(label: 'Name', controller: nameController),
                                  const SizedBox(height: 20),
                                  _buildTextField(label: 'Stadt', controller: cityController),
                                  const SizedBox(height: 20),
                                  Expanded(
                                    child: _buildDropdownField(
                                      label: 'Position',
                                      items: positions,
                                      value: selectedPosition,
                                      onChanged: (newValue) {
                                        setState(() {
                                          selectedPosition = newValue;
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 2,
                              color: Colors.black,
                              margin: const EdgeInsets.symmetric(horizontal: 16),
                            ),
                            Expanded(
                              child: Column(
                                children: [
                                  _buildTextField(label: 'Alter', controller: ageController, keyboardType: TextInputType.number),
                                  const SizedBox(height: 20),
                                  _buildTextField(label: 'Größe (cm)', controller: heightController, keyboardType: TextInputType.number),
                                  const SizedBox(height: 20),
                                  Expanded(
                                    child: _buildDropdownField(
                                      label: 'Skill Level',
                                      items: skillLevels,
                                      value: selectedSkillLevel,
                                      onChanged: (newValue) {
                                        setState(() {
                                          selectedSkillLevel = newValue;
                                        });
                                      },
                                      isExpanded: true,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Recently Played Section
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center, // Center align the heading
                        children: [
                          const Center(
                            child: Text(
                              'Zuletzt gespielt',
                              style: TextStyle(color: Colors.black, fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // First Court Image with Name below
                              Column(
                                children: [
                                  Container(
                                    width: 150,
                                    height: 150,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[700],
                                      border: Border.all(color: Colors.grey[800]!), //border for consistency
                                    ),
                                    child: firstCourtImageUrl != null
                                        ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8.0), //rounded corners
                                      child: Image.network(
                                        firstCourtImageUrl!,
                                        fit: BoxFit.cover, //image fills the container
                                        width: 150,
                                        height: 150,
                                      ),
                                    )
                                        : const Center(
                                      child: Icon(Icons.location_on, color: Colors.white, size: 50),
                                    ),
                                  ),
                                  const SizedBox(height: 8), // Space between image and name
                                  if (firstCourtName != null)
                                    SizedBox(
                                      width: 150, // width is the same as the image
                                      child: Text(
                                        firstCourtName!,
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 2, // Limit the text to 2 lines
                                        overflow: TextOverflow.ellipsis, // Add ellipsis if text overflows
                                      ),
                                    ),
                                ],
                              ),

                              // Second Court Image with Name below
                              Column(
                                children: [
                                  Container(
                                    width: 150,
                                    height: 150,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[700],
                                      border: Border.all(color: Colors.grey[800]!),
                                    ),
                                    child: secondCourtImageUrl != null
                                        ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8.0),
                                      child: Image.network(
                                        secondCourtImageUrl!,
                                        fit: BoxFit.cover,
                                        width: 150,
                                        height: 150,
                                      ),
                                    )
                                        : const Center(
                                      child: Icon(Icons.location_on, color: Colors.white, size: 50),
                                    ),
                                  ),
                                  const SizedBox(height: 8), // Space between image and name
                                  if (secondCourtName != null)
                                    SizedBox(
                                      width: 150, //width is the same as the image
                                      child: Text(
                                        secondCourtName!,
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({required String label, required TextEditingController controller, TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(color: Colors.black, fontSize: 16),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required List<String> items,
    String? value,
    required ValueChanged<String?> onChanged,
    bool isExpanded = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: value,
            isExpanded: isExpanded,
            dropdownColor: Colors.white, // Set dropdown menu background to white
            icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white, // Set the filled color for the dropdown field
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide: BorderSide.none,
              ),
            ),
            items: items.map<DropdownMenuItem<String>>((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(item, style: const TextStyle(color: Colors.black)), // Set text color to black
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
        context: context,
        builder: (context) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera),
                  title: const Text('Ein Bild aufnehmen'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Aus Bibliothek auswählen'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          );
        });
  }
}





















