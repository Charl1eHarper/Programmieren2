import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // For bar chart

class MarkerDetailsPage extends StatelessWidget {
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
  });// Konstruktor als const deklariert

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(markerName),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageCarousel(context),
            const SizedBox(height: 16),
            const Text(
              'Adresse aus Google Maps',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(markerAddress),
            const SizedBox(height: 16),
            const Text(
              'Anzahl an Leuten (wann bist du da?)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 200, child: _buildBarChart()),
            const SizedBox(height: 16),
            _buildRegistrationSection(),
            const SizedBox(height: 16),
            _buildCommentSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCarousel(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PageView.builder(
            itemCount: images.length,
            onPageChanged: (index) {
              // currentIndex = index; // Entfernt, da nicht verwendet
            },
            itemBuilder: (context, index) {
              return Image.network(
                images[index],
                fit: BoxFit.cover,
              );
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                // Logic for previous image
              },
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward),
              onPressed: () {
                // Logic for next image
              },
            ),
          ],
        ),
      ],
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
            barGroups: peoplePerHour.entries.map((entry) {
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
