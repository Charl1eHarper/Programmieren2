import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';  // Import the image picker package
import 'dart:io';  // For using File class
import 'package:firebase_storage/firebase_storage.dart'; // For file uploads
import 'package:cloud_firestore/cloud_firestore.dart'; // For Firestore
import 'package:geocoding/geocoding.dart'; // For geocoding (getting location from address)
import 'package:uuid/uuid.dart'; // For generating a unique placeId

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

  // Function to pick an image from the gallery
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

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
      print('Error uploading image: $e');
      return null;
    }
  }

  // Function to get geolocation from address
  Future<GeoPoint?> _getGeoLocation(String address) async {
    try {
      print('Getting location for address: $address');  // Debug-Ausgabe für die Adresse
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        final Location location = locations.first;
        return GeoPoint(location.latitude, location.longitude);  // Return GeoPoint
      }
    } catch (e) {
      print('Error getting location: $e');
    }
    return null;  // Return null if location is not found
  }

  // Function to save the court information in Firestore
  Future<void> _saveCourt() async {
    final String name = _nameController.text;
    final String street = _streetController.text;
    final String postalCode = _postalCodeController.text;
    final String city = _cityController.text;

    if (name.isEmpty || street.isEmpty || postalCode.isEmpty || city.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte alle Felder ausfüllen!')),
      );
      return;
    }

    // Generate the full address (including postal code for geolocation)
    final String fullAddress = '$street, $postalCode, $city';

    print('Full address: $fullAddress');  // Debug-Ausgabe der vollständigen Adresse

    // Get the geo location for the address
    final GeoPoint? geoLocation = await _getGeoLocation(fullAddress);

    if (geoLocation == null) {
      // Handle the case when geolocation fails
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fehler beim Abrufen der Geolocation!')),
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
      'address': '$street, $city', // Save address without postal code
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
    _postalCodeController.clear();
    _cityController.clear();
    _removeImage();
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
                        onPressed: _pickImage,  // Function to pick an image
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
