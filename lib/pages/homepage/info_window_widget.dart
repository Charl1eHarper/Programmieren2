import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';  // For star ratings

class InfoWindowWidget extends StatelessWidget {
  final String title;
  final String imageUrl;
  final VoidCallback onShowMorePressed;
  final VoidCallback onClosePressed;
  final VoidCallback onAddRatingPressed;

  const InfoWindowWidget({
    super.key,
    required this.title,
    required this.imageUrl,
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
          maxHeight: MediaQuery
              .of(context)
              .size
              .height * 0.5,
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
                const SizedBox(height: 8),
                // Title with padding on the left and right
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),  // Add padding to left and right
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 4),
                // Reduced space between title and rating
                // Rating Section for Ring, Netz, Platz
                _buildRatingSection("Ring"),
                _buildRatingSection("Netz"),
                _buildRatingSection("Platz"),
                const SizedBox(height: 2),
                // Reduced space between ratings and button
                // Combined Rate Button with Icon and Text
                Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  // Add 16px padding at the bottom
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero, // Remove any internal padding
                      minimumSize: const Size(40, 30), // Adjust minimum size
                      tapTargetSize: MaterialTapTargetSize
                          .shrinkWrap, // Shrink wrap the button
                    ),
                    onPressed: onAddRatingPressed, // Callback to add rating
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
                // Show More Button
                GestureDetector(
                  onTap: onShowMorePressed,
                  child: const Padding(
                    padding: EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      'Show More',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
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
  Widget _buildRatingSection(String category) {
    return Padding(
      padding: const EdgeInsets.only(left: 31),  // Apply left padding to the whole row
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center, // Ensure vertical alignment
        children: [
          // Use SizedBox with fixed width to align labels properly
          SizedBox(
            width: 50,  // Adjust this width as needed to ensure alignment
            child: Text(
              "$category:",  // The label (e.g., "Ring:", "Netz:", "Platz:")
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.right,  // Right-align the text
            ),
          ),
          const SizedBox(width: 5),  // Space between the label and the rating stars
          // Rating bar indicator
          RatingBarIndicator(
            rating: 3.5,  // Placeholder rating; can be updated later
            itemBuilder: (context, index) => const Icon(
              Icons.star,
              color: Colors.amber,
            ),
            itemCount: 5,
            itemSize: 14.0,
            direction: Axis.horizontal,
          ),
        ],
      ),
    );
  }
}
