import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';  // For star ratings

class InfoWindowWidget extends StatelessWidget {
  final String title;
  final String imageUrl;
  final double ringRating;  // Aktuelle Durchschnittsbewertung für Ring
  final double netzRating;  // Aktuelle Durchschnittsbewertung für Netz
  final double platzRating;  // Aktuelle Durchschnittsbewertung für Platz
  final VoidCallback onShowMorePressed;
  final VoidCallback onClosePressed;
  final VoidCallback onAddRatingPressed;

  const InfoWindowWidget({
    super.key,
    required this.title,
    required this.imageUrl,
    required this.ringRating,
    required this.netzRating,
    required this.platzRating,
    required this.onShowMorePressed,
    required this.onClosePressed,
    required this.onAddRatingPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(10)),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.5,
          minWidth: 200,
          maxWidth: 200,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Image at the top
                Image.network(
                  imageUrl,
                  width: double.infinity,
                  height: 125,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.image_not_supported);
                  },
                ),
                const Divider(thickness: 1, height: 0),  // Divider after image

                // Title with padding on the left and right
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const Divider(thickness: 1, height: 0),

                // Rating Section for Ring, Netz, Platz with actual values
                _buildRatingSection("Ring", ringRating),
                _buildRatingSection("Netz", netzRating),
                _buildRatingSection("Platz", platzRating),

                // Combined Rate Button with Icon and Text
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0, top: 0),
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(60, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: onAddRatingPressed,  // Callback to add rating
                    icon: const Icon(Icons.star, color: Colors.orange),
                    label: const Text(
                      "Rate!",
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const Divider(thickness: 1, height: 0),  // Divider after "Rate!" button

                // Show More Button
                GestureDetector(
                  onTap: onShowMorePressed,
                  child: const Padding(
                    padding: EdgeInsets.only(bottom: 5, top: 5),
                    child: Text(
                      'Show More',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
            // Close Button
            Positioned(
              right: 8,
              top: 8,
              child: GestureDetector(
                onTap: onClosePressed,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.7),
                  ),
                  padding: const EdgeInsets.all(5),
                  child: const Icon(
                    Icons.close,
                    color: Colors.black,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build the rating section with right-aligned text and left padding
  Widget _buildRatingSection(String category, double rating) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),  // Adjust spacing between rows
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,  // Ensure vertical alignment
        mainAxisAlignment: MainAxisAlignment.center,  // Center the whole row
        children: [
          SizedBox(
            width: 50,
            child: Text(
              "$category:",  // The label (e.g., "Ring:", "Netz:", "Platz:")
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 5),  // Space between the label and the rating stars

          // Rating bar indicator showing the average rating
          RatingBarIndicator(
            rating: rating,
            itemBuilder: (context, index) => const Icon(
              Icons.star,
              color: Colors.amber,
            ),
            itemCount: 5,
            itemSize: 16.0,
            direction: Axis.horizontal,
          ),
        ],
      ),
    );
  }
}
