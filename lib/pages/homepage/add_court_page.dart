import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';  // Import the image picker package
import 'dart:io';  // For using File class

class AddCourtPage extends StatefulWidget {
  const AddCourtPage({super.key});

  @override
  State<AddCourtPage> createState() => _AddCourtPageState();
}

class _AddCourtPageState extends State<AddCourtPage> {
  File? _selectedImage; // Variable to hold the selected image

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
                decoration: const InputDecoration(
                  labelText: 'Platzname',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: screenHeight * 0.02),

              // Straße Hausnr. TextField
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Straße Hausnr.',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: screenHeight * 0.02),

              // Postleitzahl TextField
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Postleitzahl',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: screenHeight * 0.02),

              // Ort TextField
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Ort',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: screenHeight * 0.04),

              // Platz hinzufügen Button
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    // Logik zum Hinzufügen eines Platzes
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(
                        vertical: screenHeight * 0.02,
                        horizontal: screenWidth * 0.2),
                  ),
                  child: const Text(
                    'Platz hinzufügen',
                    style: TextStyle(color: Colors.white), // Weißer Text
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
