import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';  // For picking images from gallery or camera
import 'dart:io';  // For handling file operations
import 'package:firebase_storage/firebase_storage.dart'; // For uploading images to Firebase Storage
import 'package:cloud_firestore/cloud_firestore.dart'; // For saving court information in Firestore
import 'package:geocoding/geocoding.dart'; // For converting address to geolocation
import 'package:uuid/uuid.dart'; // For generating unique placeId
import 'package:flutter/services.dart';  // For input formatters

class AddCourtPage extends StatefulWidget {
  const AddCourtPage({super.key});

  @override
  State<AddCourtPage> createState() => _AddCourtPageState();
}

class _AddCourtPageState extends State<AddCourtPage> {
  File? _selectedImage; // Holds the selected image file
  final TextEditingController _nameController = TextEditingController(); // Controller for court name input
  final TextEditingController _streetController = TextEditingController(); // Controller for street input
  final TextEditingController _postalCodeController = TextEditingController(); // Controller for postal code input
  final TextEditingController _cityController = TextEditingController(); // Controller for city input

  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Reference to Firestore instance
  final FirebaseStorage _storage = FirebaseStorage.instance; // Reference to Firebase Storage
  final _uuid = const Uuid(); // For generating unique placeId

  bool _isClicked = false; // Tracks if the button has been clicked

  // Function to show a dialog for choosing between camera or gallery
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
                  Navigator.of(context).pop(); // Close the dialog
                  _pickImage(ImageSource.camera); // Capture image from camera
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Aus Galerie auswählen'),
                onTap: () {
                  Navigator.of(context).pop(); // Close the dialog
                  _pickImage(ImageSource.gallery); // Select image from gallery
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Function to pick an image from the specified source (camera or gallery)
  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      // Update the selected image state
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

  // Function to upload the selected image to Firebase Storage
  Future<String?> _uploadImage(File image) async {
    try {
      final String imageId = _uuid.v4(); // Generate a unique ID for the image
      final Reference storageRef = _storage.ref().child('basketball_courts/$imageId'); // Storage path for the image
      final UploadTask uploadTask = storageRef.putFile(image); // Upload the image file
      final TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL(); // Return the download URL of the uploaded image
    } catch (e) {
      return null; // Return null if an error occurs
    }
  }

  // Function to get geolocation from the provided address
  Future<GeoPoint?> _getGeoLocation(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address); // Get location from the address
      if (locations.isNotEmpty) {
        final Location location = locations.first;
        return GeoPoint(location.latitude, location.longitude); // Return the GeoPoint
      } else {
        return null; // Return null if no location is found
      }
    } catch (e) {
      return null; // Return null in case of an error
    }
  }

  // Function to check if a court with the same address already exists in Firestore
  Future<bool> _checkIfCourtExists(String street, String city) async {
    final String fullAddress = '$street, $city'; // Construct the full address

    final QuerySnapshot result = await _firestore
        .collection('basketball_courts')
        .where('address', isEqualTo: fullAddress)
        .limit(1)
        .get(); // Query Firestore for matching addresses

    return result.docs.isNotEmpty; // Return true if a court exists, false otherwise
  }

  // Function to save the court information to Firestore
  Future<void> _saveCourt() async {
    final String name = _nameController.text; // Get court name
    final String street = _streetController.text; // Get street
    final String city = _cityController.text; // Get city

    // Check if required fields are filled and image is selected
    if (name.isEmpty || street.isEmpty || city.isEmpty || _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte alle Felder ausfüllen und ein Bild hinzufügen!')),
      );
      return;
    }

    // Generate the full address
    final String fullAddress = '$street, $city';

    // Check if the court with the same address already exists
    bool exists = await _checkIfCourtExists(street, city);
    if (exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dieser Platz existiert bereits!')),
      );
      return;
    }

    // Get geolocation from the provided address
    final GeoPoint? geoLocation = await _getGeoLocation(fullAddress);

    if (geoLocation == null) {
      // Show error if geolocation is not found
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adresse nicht gefunden!')),
      );
      return;
    }

    // Upload the selected image to Firebase Storage if available
    String? imageUrl;
    if (_selectedImage != null) {
      imageUrl = await _uploadImage(_selectedImage!);
    }

    // Generate a unique placeId for the court
    final String placeId = _uuid.v4();

    // Save court data to Firestore, including image URL and GeoPoint
    await _firestore.collection('basketball_courts').doc(placeId).set({
      'name': name,
      'address': fullAddress,
      'location': geoLocation,
      'image_urls': imageUrl != null ? [imageUrl] : [], // If image is uploaded, add the URL
      'placeId': placeId,
    });

    // Show confirmation message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Platz erfolgreich hinzugefügt!')),
    );

    // Clear the form and reset the state
    _nameController.clear();
    _streetController.clear();
    _postalCodeController.clear();
    _cityController.clear();
    _removeImage(); // Remove selected image
  }

  // Handle button click animation and trigger court saving after animation
  void _handleClick() {
    setState(() {
      _isClicked = true;
    });

    // Reset the animation state after 300ms and save court
    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        _isClicked = false;
      });
      _saveCourt(); // Save court after the animation
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height; // Get screen height for responsive UI
    final screenWidth = MediaQuery.of(context).size.width; // Get screen width for responsive UI

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(
          color: Colors.white, // Set back button color to white
        ),
        title: const Text(
          'Add Court',
          style: TextStyle(
            color: Colors.white, // Set title color to white
            fontWeight: FontWeight.bold, // Set title text to bold
          ),
        ),
        centerTitle: false, // Align title to the left
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Go back to the previous screen
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
              // Display placeholder or selected image
              Stack(
                children: [
                  Container(
                    height: screenHeight * 0.25,
                    width: screenWidth * 0.8,
                    decoration: BoxDecoration(
                      color: Colors.grey[300], // Gray background for placeholder
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
                        onPressed: _showImageSourceDialog, // Open image picker dialog
                      ),
                    ),
                  ),
                  if (_selectedImage != null)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: _removeImage, // Remove the selected image
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

              // TextField for court name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Platzname',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: screenHeight * 0.02),

              // TextField for street and house number
              TextFormField(
                controller: _streetController,
                decoration: const InputDecoration(
                  labelText: 'Straße Hausnr.',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: screenHeight * 0.02),

              // TextField for postal code with input formatting
              TextFormField(
                controller: _postalCodeController,
                decoration: const InputDecoration(
                  labelText: 'Postleitzahl',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number, // Numeric keyboard
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(5), // Limit to 5 digits
                ],
              ),
              SizedBox(height: screenHeight * 0.02),

              // TextField for city
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(
                  labelText: 'Ort',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: screenHeight * 0.04),

              // Button for adding court with animation
              Center(
                child: GestureDetector(
                  onTap: _handleClick, // Handle button click
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut, // Animate size and color changes
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

              // Instruction text for adding courts
              const Center(child: Text('Bitte füge nur existierende Plätze hinzu!')),
            ],
          ),
        ),
      ),
    );
  }
}
