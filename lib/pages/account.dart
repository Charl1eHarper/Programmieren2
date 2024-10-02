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
  String? selectedLevel;

  final List<String> positions = ['PG', 'SG', 'SF', 'PF', 'C'];
  final List<String> levels = ['Level 1', 'Level 2', 'Level 3', 'Level 4', 'Level 5'];

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
          nameController.text = data['name'] ?? '';
          ageController.text = data['age']?.toString() ?? '';
          cityController.text = data['city'] ?? '';
          heightController.text = data['height']?.toString() ?? '';
          selectedPosition = positions.contains(data['position']) ? data['position'] : null;
          selectedLevel = levels.contains(data['level']) ? data['level'] : null;
          _profileImageUrl = data['profileImage'] ?? '';
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to load profile: $e")),
        );
      }
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
          'level': selectedLevel ?? levels[0],
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
        color: Colors.grey[850],  // Ensure background covers entire screen
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
                              radius: 100,  // Profile picture size
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
                                  radius: 28,  // Camera icon size
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
                                  _buildDropdownField(
                                      label: 'Position', items: positions, value: selectedPosition, onChanged: (newValue) {
                                    setState(() {
                                      selectedPosition = newValue;
                                    });
                                  }),
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
                                  _buildDropdownField(
                                      label: 'Level', items: levels, value: selectedLevel, onChanged: (newValue) {
                                    setState(() {
                                      selectedLevel = newValue;
                                    });
                                  }),
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
                              // Placeholder for the first court
                              Container(
                                width: 150,
                                height: 150,
                                color: Colors.grey[700],
                                child: Center(
                                  child: Icon(Icons.location_on, color: Colors.white, size: 50),
                                ),
                              ),
                              // Placeholder for the second court
                              Container(
                                width: 150,
                                height: 150,
                                color: Colors.grey[700],
                                child: Center(
                                  child: Icon(Icons.location_on, color: Colors.white, size: 50),
                                ),
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

  Widget _buildDropdownField({required String label, required List<String> items, String? value, required ValueChanged<String?> onChanged}) {
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
















