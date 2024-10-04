import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io'; // For File handling

class AccountPage extends StatefulWidget {
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
  final List<String> skillLevels = ['Beginner', 'Intermediate', 'Advanced', 'Expert', 'Pro']; // Updated skill levels

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
          SnackBar(content: Text("Failed to load profile: $e")),
        );
      }
    }
  }

  Future<void> _fetchCourtDetails(List<dynamic> lastCourts) async {
    try {
      if (lastCourts.isNotEmpty) {
        // First court
        if (lastCourts.length > 0) {
          var firstCourtId = lastCourts[lastCourts.length - 1]['placeId'];
          var firstCourtDoc = await FirebaseFirestore.instance.collection('basketball_courts').doc(firstCourtId).get();
          if (firstCourtDoc.exists) {
            var courtData = firstCourtDoc.data() as Map<String, dynamic>;

            setState(() {
              firstCourtImageUrl = (courtData['imageUrls'] != null && courtData['imageUrls'].isNotEmpty)
                  ? courtData['imageUrls'][0]
                  : null;
              firstCourtName = courtData['name'];

              print("First Court PlaceId: $firstCourtId");
              print("First Court Image URL: $firstCourtImageUrl");
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

              print("Second Court PlaceId: $secondCourtId");
              print("Second Court Image URL: $secondCourtImageUrl");
            });
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load court details: $e")),
      );
    }
  }

  void _saveUserProfile() async {
    if (user != null) {
      int age = int.tryParse(ageController.text) ?? -1;
      double height = double.tryParse(heightController.text) ?? 0.0;

      if (age < 0) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Age cannot be less than 0")));
        return;
      }

      if (height <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Height must be in centimeters")));
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
          SnackBar(content: Text("Profile saved successfully")),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to save profile: $e")),
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("No image selected!")));
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
        SnackBar(content: Text("Profile image uploaded and saved successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to upload image: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text('Edit Profile', style: TextStyle(color: Colors.white, fontSize: 22)),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveUserProfile,
          ),
        ],
      ),
      body: Container(
        color: Colors.grey[850],
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Center(
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 100,
                              backgroundColor: Colors.grey[400],
                              backgroundImage: _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                                  ? NetworkImage(_profileImageUrl!)
                                  : null,
                              child: _profileImageUrl == null || _profileImageUrl!.isEmpty
                                  ? Icon(Icons.person, size: 100, color: Colors.white)
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () {
                                  _showImagePickerOptions();
                                },
                                child: CircleAvatar(
                                  backgroundColor: Colors.teal,
                                  radius: 28,
                                  child: Icon(Icons.camera_alt, color: Colors.white, size: 28),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 40),

                      // Profile form fields
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  _buildTextField(label: 'Name', controller: nameController),
                                  SizedBox(height: 20),
                                  _buildTextField(label: 'City', controller: cityController),
                                  SizedBox(height: 20),
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
                              color: Colors.white,
                              margin: EdgeInsets.symmetric(horizontal: 16),
                            ),
                            Expanded(
                              child: Column(
                                children: [
                                  _buildTextField(label: 'Age', controller: ageController, keyboardType: TextInputType.number),
                                  SizedBox(height: 20),
                                  _buildTextField(label: 'Height (cm)', controller: heightController, keyboardType: TextInputType.number),
                                  SizedBox(height: 20),
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

                      SizedBox(height: 40),

// Recently Played Section
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center, // Center align the heading
                        children: [
                          Center(
                            child: Text(
                              'Recently Played',
                              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                          ),
                          SizedBox(height: 20),
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
                                      border: Border.all(color: Colors.grey[800]!), // Optional border for consistency
                                    ),
                                    child: firstCourtImageUrl != null
                                        ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8.0), // Optional: Add rounded corners
                                      child: Image.network(
                                        firstCourtImageUrl!,
                                        fit: BoxFit.cover, // Cover ensures the image fills the container
                                        width: 150,
                                        height: 150,
                                      ),
                                    )
                                        : Center(
                                      child: Icon(Icons.location_on, color: Colors.white, size: 50),
                                    ),
                                  ),
                                  SizedBox(height: 8), // Space between image and name
                                  if (firstCourtName != null)
                                    Container(
                                      width: 150, // Ensure the width is the same as the image
                                      child: Text(
                                        firstCourtName!,
                                        style: TextStyle(
                                          color: Colors.white,
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
                                        : Center(
                                      child: Icon(Icons.location_on, color: Colors.white, size: 50),
                                    ),
                                  ),
                                  SizedBox(height: 8), // Space between image and name
                                  if (secondCourtName != null)
                                    Container(
                                      width: 150, // Ensure the width is the same as the image
                                      child: Text(
                                        secondCourtName!,
                                        style: TextStyle(
                                          color: Colors.white,
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
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: TextStyle(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey[800],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField({required String label, required List<String> items, String? value, required ValueChanged<String?> onChanged, bool isExpanded = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: value,
            isExpanded: isExpanded,
            dropdownColor: Colors.grey[850],
            icon: Icon(Icons.arrow_drop_down, color: Colors.white),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey[800],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide: BorderSide.none,
              ),
            ),
            items: items.map<DropdownMenuItem<String>>((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(item, style: TextStyle(color: Colors.white, fontSize: 16)),
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
                  leading: Icon(Icons.camera),
                  title: Text('Take Photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.photo_library),
                  title: Text('Choose from Library'),
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





















