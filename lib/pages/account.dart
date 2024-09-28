import 'package:flutter/material.dart';

class AccountPage extends StatefulWidget {
  @override
  _AccountPageState createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController heightController = TextEditingController();
  final TextEditingController positionController = TextEditingController();
  final TextEditingController levelController = TextEditingController();
  final TextEditingController goalController = TextEditingController();
  final TextEditingController shoeController = TextEditingController();

  bool _isPlayerInfoExpanded = false; // Flag to control dropdown expansion

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
      ),
      body: LayoutBuilder(  // Use LayoutBuilder to ensure the content takes up the full height
          builder: (context, constraints) {
            return Container(
              color: Colors.grey[850],  // Set the background color for the entire page
              height: constraints.maxHeight,  // Make sure the container takes the full available height
              padding: EdgeInsets.all(16.0),  // Padding around the content
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: 20),
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 80,  // Larger profile picture
                            backgroundColor: Colors.grey[400], // Placeholder background
                            child: Icon(Icons.person, size: 80, color: Colors.white), // Placeholder icon
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              backgroundColor: Colors.teal,
                              radius: 22,  // Adjusted camera icon size
                              child: Icon(Icons.camera_alt, color: Colors.white, size: 22),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 40),
                    _buildTextField(label: 'Name', controller: nameController),
                    _buildTextField(label: 'Age', controller: ageController),
                    _buildTextField(label: 'City', controller: cityController), // City field
                    SizedBox(height: 12),

                    // ExpansionTile for Player Info dropdown
                    ExpansionTile(
                      tilePadding: EdgeInsets.symmetric(horizontal: 16), // Consistent padding
                      title: Text(
                        'Player Info',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      backgroundColor: Colors.grey[850],
                      textColor: Colors.white,
                      iconColor: Colors.white,
                      collapsedIconColor: Colors.white,
                      initiallyExpanded: _isPlayerInfoExpanded,
                      onExpansionChanged: (expanded) {
                        setState(() {
                          _isPlayerInfoExpanded = expanded;
                        });
                      },
                      children: [
                        _buildTextField(label: 'Height', controller: heightController),
                        _buildTextField(label: 'Position', controller: positionController),
                        _buildTextField(label: 'Level', controller: levelController),
                        _buildTextField(label: 'Goal', controller: goalController),
                        _buildTextField(label: 'Shoe', controller: shoeController),
                      ],
                    ),
                    SizedBox(height: 20),  // Extra padding at the bottom
                  ],
                ),
              ),
            );
          }
      ),
    );
  }

  // Helper method to create text fields
  Widget _buildTextField({required String label, required TextEditingController controller}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0), // Padding around the field
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold), // Consistent font size and style
          ),
          SizedBox(height: 8),
          TextField(
            controller: controller,
            style: TextStyle(color: Colors.white, fontSize: 14), // Consistent font size
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey[800],  // Background for input fields
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12), // Reduced padding for smaller fields
            ),
          ),
          SizedBox(height: 12), // Reduced space between fields
        ],
      ),
    );
  }
}





