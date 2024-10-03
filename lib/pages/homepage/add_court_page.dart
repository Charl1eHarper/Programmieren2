import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';  // Import the image picker package
import 'dart:io';  // For using File class
import 'package:firebase_storage/firebase_storage.dart'; // For file uploads
import 'package:cloud_firestore/cloud_firestore.dart'; // For Firestore
import 'package:geocoding/geocoding.dart'; // For geocoding (getting location from address)
import 'package:uuid/uuid.dart'; // For generating a unique placeId
import 'package:flutter/services.dart';  // Import for FilteringTextInputFormatter

class AddCourtPage extends StatefulWidget {
  const AddCourtPage({super.key});

  @override
  State<AddCourtPage> createState() => _AddCourtPageState();
}

class _AddCourtPageState extends State<AddCourtPage> {
  File? _selectedImage; // Variable to hold the selected image
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _uuid = const Uuid(); // For generating unique placeId

  bool _isClicked = false; // Variable to track button click

  // Function to show dialog to choose between camera and gallery
  Future<void> _showImageSourceDialog() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Foto aufnehmen'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Aus Galerie auswählen'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Function to pick an image from the gallery or camera
  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  // Function to remove the selected image
  void _removeImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  // Function to upload the image to Firebase Storage
  Future<String?> _uploadImage(File image) async {
    try {
      final String imageId = _uuid.v4();
      final Reference storageRef = _storage.ref().child('basketball_courts/$imageId');
      final UploadTask uploadTask = storageRef.putFile(image);
      final TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  // Function to get geolocation from address
  Future<GeoPoint?> _getGeoLocation(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        final Location location = locations.first;
        return GeoPoint(location.latitude, location.longitude);  // Return GeoPoint
      } else {
        return null;  // Explicitly return null if no locations are found
      }
    } catch (e) {
      return null;  // Return null if an exception occurs
    }
  }

  // Function to check if an address already exists in Firestore
  Future<bool> _checkIfCourtExists(String street, String city) async {
    final String fullAddress = '$street, $city';

    final QuerySnapshot result = await _firestore
        .collection('basketball_courts')
        .where('address', isEqualTo: fullAddress)
        .limit(1)
        .get();

    return result.docs.isNotEmpty;
  }

  // Function to save the court information in Firestore
  Future<void> _saveCourt() async {
    final String name = _nameController.text;
    final String street = _streetController.text;
    final String city = _cityController.text;

    if (name.isEmpty || street.isEmpty || city.isEmpty || _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte alle Felder ausfüllen und ein Bild hinzufügen!')),
      );
      return;
    }

    // Generate the full address
    final String fullAddress = '$street, $city';

    // Check if court with the same address already exists
    bool exists = await _checkIfCourtExists(street, city);
    if (exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dieser Platz existiert bereits!')),
      );
      return;
    }

    // Get the geo location for the address
    final GeoPoint? geoLocation = await _getGeoLocation(fullAddress);

    if (geoLocation == null) {
      // Handle the case when geolocation fails
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adresse nicht gefunden!')),
      );
      return;
    }

    // Upload image if available
    String? imageUrl;
    if (_selectedImage != null) {
      imageUrl = await _uploadImage(_selectedImage!);
    }

    // Generate a unique placeId
    final String placeId = _uuid.v4();

    // Save data to Firestore with GeoPoint
    await _firestore.collection('basketball_courts').doc(placeId).set({
      'name': name,
      'address': fullAddress, // Save the full address
      'location': geoLocation, // Store GeoPoint object
      'image_urls': imageUrl != null ? [imageUrl] : [], // Store image URL if available
      'placeId': placeId,
    });

    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Platz erfolgreich hinzugefügt!')),
    );

    // Clear form
    _nameController.clear();
    _streetController.clear();
    _postalCodeController.clear();  // Clear postal code as well
    _cityController.clear();
    _removeImage();  // Clear the selected image

    // Navigate back to the HomePage and center map on user's location
    Navigator.of(context).pop();  // Go back to the HomePage
  }


  // Handle button click animation
  void _handleClick() {
    setState(() {
      _isClicked = true;
    });

    // Reset animation after a short delay
    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        _isClicked = false;
      });
      _saveCourt(); // Save court after animation
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(
          color: Colors.white, // Setzt die Farbe des Icons (Pfeil) auf weiß
        ),
        title: const Text(
          'Add Court',
          style: TextStyle(
            color: Colors.white, // Setzt die Farbe des Titels auf weiß
            fontWeight: FontWeight.bold, // Setzt den Text auf fett
          ),
        ),
        centerTitle: false, // Titel linksbündig machen
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Zurück zur vorherigen Seite
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.1, vertical: screenHeight * 0.02),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bild-Platzhalter mit + Icon oder ausgewähltes Bild
              Stack(
                children: [
                  Container(
                    height: screenHeight * 0.25,
                    width: screenWidth * 0.8,
                    decoration: BoxDecoration(
                      color: Colors.grey[300], // Grauer Hintergrund für den Platzhalter
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey[400]!,
                        width: 2,
                      ),
                    ),
                    child: _selectedImage != null
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _selectedImage!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    )
                        : Center(
                      child: IconButton(
                        icon: const Icon(Icons.add_a_photo,
                            size: 50, color: Colors.black),
                        onPressed: _showImageSourceDialog,  // Show dialog to pick image source
                      ),
                    ),
                  ),
                  if (_selectedImage != null)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: _removeImage,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.7),
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(5),
                          child: const Icon(
                            Icons.delete,
                            color: Colors.red,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: screenHeight * 0.03),

              // Platzname TextField
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Platzname',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: screenHeight * 0.02),

              // Straße Hausnr. TextField
              TextFormField(
                controller: _streetController,
                decoration: const InputDecoration(
                  labelText: 'Straße Hausnr.',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: screenHeight * 0.02),

              // Postleitzahl TextField
              TextFormField(
                controller: _postalCodeController,
                decoration: const InputDecoration(
                  labelText: 'Postleitzahl',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number, // Set keyboard type to number
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(5), // Limit to 5 digits
                ], // Allow only digits and limit to 5
              ),
              SizedBox(height: screenHeight * 0.02),

              // Ort TextField
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(
                  labelText: 'Ort',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: screenHeight * 0.04),

              // Platz hinzufügen Button with animation
              Center(
                child: GestureDetector(
                  onTap: _handleClick, // Trigger animation and save court
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    width: _isClicked ? screenWidth * 0.5 : screenWidth * 0.6,
                    height: screenHeight * 0.07,
                    decoration: BoxDecoration(
                      color: _isClicked ? Colors.orangeAccent : Colors.black, // Animate color change
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Platz hinzufügen',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.02),

              // Hinweistext
              const Center(child: Text('Bitte füge nur existierende Plätze hinzu!')),
            ],
          ),
        ),
      ),
    );
  }
}
