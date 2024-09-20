import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For formatting the date

class MarkerDetailsPage extends StatefulWidget {
  final String markerName;
  final String markerAddress;
  final List<String> images;
  final Map<int, int> peoplePerHour; // Placeholder for people count per hour

  const MarkerDetailsPage({
    super.key,
    required this.markerName,
    required this.markerAddress,
    required this.images,
    required this.peoplePerHour,
  });

  @override
  _MarkerDetailsPageState createState() => _MarkerDetailsPageState();
}

class _MarkerDetailsPageState extends State<MarkerDetailsPage> {
  late PageController _pageController;
  int _currentIndex = 0;
  late int _nextHour; // Variable to hold the next full hour

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);

    // Get the current time and calculate the next full hour
    DateTime now = DateTime.now();
    int currentHour = now.hour;
    int currentMinute = now.minute;

    // If it's past the current hour (e.g., 20:41), set the next hour to 21
    setState(() {
      _nextHour = (currentMinute > 0) ? (currentHour + 1) % 24 : currentHour;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final currentDate = DateFormat('EEEE, dd MMM yyyy').format(DateTime.now()); // Get the current date

    // Format the address to "Streetname Number, Postal Code City"
    String formattedAddress = formatAddress(widget.markerAddress);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
            widget.markerName,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold) // Set the title text to white
        ),
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
            // Image carousel
            SizedBox(
              height: screenHeight * 0.30,
              child: _buildImageCarousel(),
            ),
            const SizedBox(height: 10), // Space between image and address
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                formattedAddress,
                style: const TextStyle(
                  fontSize: 17,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Display current date
                  Text(
                    '$currentDate',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  // Section for "Anzahl an Leuten" (People count for each hour)
                  SizedBox(
                    height: screenHeight * 0.15,  // Reduced height for circles
                    child: _buildScrollableHourCircles(screenWidth),
                  ),
                  const SizedBox(height: 12), // Reduced space between circles and button

                  // Registration button
                  _buildRegistrationSection(screenWidth),

                  const SizedBox(height: 12), // Same space between button and comments

                  // Comment section
                  _buildCommentSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Function to format the address
  String formatAddress(String address) {
    List<String> addressParts = address.split(',');

    // If the address has more than 2 parts (e.g., Streetname Number, Postal Code City, Country)
    // We remove the last part, assuming it's the country.
    if (addressParts.length > 2) {
      addressParts.removeLast(); // Remove the last part, which is the country.
    }

    // Join the remaining parts back into the desired format "Streetname Number, Postal Code City"
    return addressParts.join(',').trim();
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

  Widget _buildScrollableHourCircles(double screenWidth) {
    return Container(
      height: 5, // Set an appropriate height for the circles and text to be visible
      decoration: BoxDecoration(
        border: Border.all(color: Colors.orange, width: 2.0), // Orange outline with 2.0 width
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal, // Horizontal scrolling
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center, // Center items vertically
          children: List.generate(24, (index) {
            final int peopleCount = widget.peoplePerHour[index] ?? 0; // Default to 0 if no data

            // Determine if this is the next hour, and set the color accordingly
            final bool isNextHour = index == _nextHour;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0), // Horizontal padding for spacing
              child: Column(
                mainAxisSize: MainAxisSize.min, // Minimize vertical space
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '${index} Uhr', // Display the hour
                    style: TextStyle(
                      fontSize: 14, // Slightly smaller font size for the hour label
                      color: isNextHour ? Colors.orange : Colors.black, // Mark the next hour in orange
                    ),
                  ),
                  const SizedBox(height: 4), // Adjusted space between text and circle
                  Container(
                    width: screenWidth / 10, // Dynamically set the width based on screen size
                    height: screenWidth / 10, // Same height as width for perfect circle
                    decoration: BoxDecoration(
                      color: isNextHour ? Colors.orange : Colors.black, // Change circle color for the next hour
                      shape: BoxShape.circle, // Make it a circle
                    ),
                    child: Center(
                      child: Text(
                        '$peopleCount', // Display the people count
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
            );
          }),
        ),
      ),
    );
  }




  // Updated Registration section with reduced padding and dynamic size
  Widget _buildRegistrationSection(double screenWidth) {
    return Center(
      child: SizedBox(
        width: screenWidth * 0.6,  // Full-width button
        child: TextButton(
          style: TextButton.styleFrom(
            backgroundColor: Colors.black, // Set background color to black
            padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20), // Dynamically set padding
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30), // Rounded corners
            ),
          ),
          onPressed: () {
            // Placeholder action for user registration
            // In future, connect to database and allow user to select a time
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Wann bist du da?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: screenWidth * 0.045,  // Dynamically set font size based on screen width
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),  // Space between text and icon
              Icon(
                Icons.add_circle,
                color: Colors.white,
                size: screenWidth * 0.06, // Dynamically set icon size
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Kommentare', style: TextStyle(fontWeight: FontWeight.bold)),
        _buildComment('User1', 'Der Platz ist ok, aber nicht mehr!'),
        _buildComment('User2', 'Nicht schlecht aber auch nicht krass'),
      ],
    );
  }

  Widget _buildComment(String username, String comment) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        children: [
          const Icon(Icons.account_circle, size: 40),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(username, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(comment),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Method to build arrow buttons for the carousel
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
