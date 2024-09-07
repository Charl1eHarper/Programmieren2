import 'package:flutter/material.dart';

class ExpandedInfoWindow extends StatelessWidget {
  final String imageUrl;
  final String title;
  final int ringRating;
  final int netRating;
  final int courtRating;

  const ExpandedInfoWindow({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.ringRating,
    required this.netRating,
    required this.courtRating,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 16,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        // Remove fixed height and make it flexible
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,  // Allow the height to be flexible
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              imageUrl,
              width: double.infinity,
              height: 150,  // Fixed height for the image
              fit: BoxFit.cover,
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Adresse aus google Maps',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildRating('Ring', ringRating),
                _buildRating('Netz', netRating),
                _buildRating('Platz', courtRating),
              ],
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.center,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close the modal
                },
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRating(String label, int rating) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
        Text(
          '$rating von 5',
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ],
    );
  }
}

