import 'package:flutter/material.dart';

class AddCourtPage extends StatelessWidget {
  const AddCourtPage({super.key});

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
              // Bild-Platzhalter mit + Icon
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
                child: Center(
                  child: IconButton(
                    icon: const Icon(Icons.add_a_photo,
                        size: 50, color: Colors.black),
                    onPressed: () {
                      // Funktion zum Hinzufügen von Bildern
                    },
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.03),

              // Name TextField
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: screenHeight * 0.02),

              // Adresse TextField
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Adresse',
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
              const Center(child: Text('Bitte füge nur existierende Plätze hinzu!')
              ),
            ],
          ),
        ),
      ),
    );
  }
}
