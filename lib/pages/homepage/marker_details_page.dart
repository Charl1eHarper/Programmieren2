import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // For bar chart

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

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(widget.markerName),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kein Padding für das Bildkarussell
            SizedBox(
              height: screenHeight * 0.30,  // Dynamische Höhe, z.B. 25% der Bildschirmhöhe
              child: _buildImageCarousel(),
            ),
            // Padding für die anderen Elemente
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  const Text(
                    'Adresse aus Google Maps',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(widget.markerAddress),
                  const SizedBox(height: 16),
                  const Text(
                    'Anzahl an Leuten (wann bist du da?)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  // Balkendiagramm dynamisch anpassen
                  SizedBox(
                    height: screenHeight * 0.3,  // Dynamische Höhe, z.B. 30% der Bildschirmhöhe
                    child: _buildBarChart(),
                  ),
                  const SizedBox(height: 16),
                  _buildRegistrationSection(),
                  const SizedBox(height: 16),
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
      alignment: Alignment.center, // Zentriere den Inhalt im Stack
      children: [
        PageView.builder(
          controller: _pageController, // PageController wird verwendet
          itemCount: widget.images.length,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index; // Aktueller Index wird gesetzt
            });
          },
          itemBuilder: (context, index) {
            return Image.network(
              widget.images[index],
              width: double.infinity,  // Über die gesamte Breite des Bildschirms
              fit: BoxFit.cover,  // Das Bild wird zugeschnitten, um den verfügbaren Raum zu füllen
            );
          },
        ),
        // Linker Pfeil
        Positioned(
          left: 16,  // Abstand vom linken Rand
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
        // Rechter Pfeil
        Positioned(
          right: 16,  // Abstand vom rechten Rand
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

  // Methode zum Erstellen der Pfeil-Buttons mit einem transparenten Kreis dahinter
  Widget _buildArrowButton({required IconData icon, required VoidCallback onPressed}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.5),  // Transparenter grauer Hintergrund
        shape: BoxShape.circle,  // Rundes Design
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),  // Weißer Pfeil
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildBarChart() {
    return ListView(
      scrollDirection: Axis.horizontal,
      children: [
        BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: 10, // Max height of bars
            barGroups: widget.peoplePerHour.entries.map((entry) {
              return BarChartGroupData(
                x: entry.key, // The hour
                barRods: [
                  BarChartRodData(
                    toY: entry.value.toDouble(), // Updated to `toY`
                    width: 15,
                    color: Colors.blue, // Updated from `colors` to `color`
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildRegistrationSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Wann bist du da?'),
        IconButton(
          icon: const Icon(Icons.add_circle, color: Colors.green),
          onPressed: () {
            // Registration action
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
        // Add more placeholder comments if needed
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
}
