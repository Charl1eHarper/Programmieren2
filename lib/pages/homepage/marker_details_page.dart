import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For formatting the date

class MarkerDetailsPage extends StatefulWidget {
  final String markerName;
  final String markerAddress;
  final List<String> images;
  final Map<int, int> peoplePerHour; // Placeholder for people count per hour

  const MarkerDetailsPage({
    super.key,  // 'key' direkt als Superparameter übergeben
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

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          widget.markerName,
          style: const TextStyle(color: Colors.black, fontSize: 22)// Set the title text to white
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black,),
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
            // Reduced padding between image and address
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0), // Adjusted padding for better alignment
              child: Text(
                widget.markerAddress,
                style: const TextStyle(
                  fontSize: 15, // Larger font size for the address
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
                    '$currentDate', // Display formatted date
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  // Section for "Anzahl an Leuten" (People count for each hour)
                  SizedBox(
                    height: screenHeight * 0.2,  // Smaller height since we're using circles
                    child: _buildScrollableHourCircles(screenWidth), // Scrollable circles
                  ),
                  const SizedBox(height: 16),

                  // Registration button
                  _buildRegistrationSection(),

                  const SizedBox(height: 16),

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

  // Function to build circles under each hour
  Widget _buildScrollableHourCircles(double screenWidth) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: 24, // 24 hours in a day
      itemBuilder: (context, index) {
        final int peopleCount = widget.peoplePerHour[index] ?? 0; // Default to 0 if no data

        // Determine if this is the next hour, and set the color accordingly
        final bool isNextHour = index == _nextHour;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: Column(
            children: [
              Text(
                '${index} Uhr', // Display the hour
                style: TextStyle(
                  fontSize: 15,
                  color: isNextHour ? Colors.orange : Colors.black, // Mark the next hour in orange
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: screenWidth / 10, // Dynamically set the width based on screen size
                height: screenWidth / 10, // Height same as width to make a perfect circle
                decoration: const BoxDecoration(
                  color: Colors.grey, // Default background color for the circle
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
      },
    );
  }

  // Registration section with a button
  Widget _buildRegistrationSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Wann bist du da?'),
        IconButton(
          icon: const Icon(Icons.add_circle, color: Colors.green),
          onPressed: () {
            // Placeholder action for user registration
            // In future, connect to database and allow user to select a time
          },
        ),
      ],
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
