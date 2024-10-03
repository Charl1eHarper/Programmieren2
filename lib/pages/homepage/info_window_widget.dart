import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';  // For star ratings

class InfoWindowWidget extends StatelessWidget {
  final String title;
  final String imageUrl;
  final double ringRating;  // Average rating for Ring
  final double netzRating;  // Average rating for Netz
  final double platzRating; // Average rating for Platz
  final VoidCallback onShowMorePressed; // Callback for "Show More" action
  final VoidCallback onClosePressed; // Callback for closing the info window
  final VoidCallback onAddRatingPressed; // Callback for adding a rating

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

  // Helper method to build the rating section for each category
  Widget _buildRatingSection(String category, double rating) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),  // Add vertical spacing between rating rows
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,  // Align content vertically
        mainAxisAlignment: MainAxisAlignment.center,  // Center content horizontally
        children: [
          SizedBox(
            width: 50, // Fixed width for category label
            child: Text(
              "$category:",  // Category label (e.g., "Ring:", "Netz:", "Platz:")
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
              textAlign: TextAlign.right, // Align text to the right
            ),
          ),
          const SizedBox(width: 5),  // Space between label and rating stars

          // Rating bar showing average rating for the category
          RatingBarIndicator(
            rating: rating,
            itemBuilder: (context, index) => const Icon(
              Icons.star,
              color: Colors.amber,
            ),
            itemCount: 5,  // Maximum 5 stars
            itemSize: 16.0, // Size of each star
            direction: Axis.horizontal, // Display stars horizontally
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(10)),  // Rounded corners for the container
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.5,  // Limit max height to half the screen
          minWidth: 200,  // Minimum width for the container
          maxWidth: 200,  // Maximum width for the container
        ),
        decoration: const BoxDecoration(
          color: Colors.white,  // White background for the container
          boxShadow: [
            BoxShadow(
              color: Colors.black26,  // Shadow color
              blurRadius: 10,  // Blur effect for the shadow
              offset: Offset(0, 2),  // Vertical offset for the shadow
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,  // Align all content in the center
              mainAxisSize: MainAxisSize.min,  // Minimize the size of the column to its content
              children: [
                // Display image at the top
                Image.network(
                  imageUrl,
                  width: double.infinity,  // Image should take up full width
                  height: 125,  // Fixed height for the image
                  fit: BoxFit.cover,  // Cover the entire area without distorting the image
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.image_not_supported);  // Fallback if image fails to load
                  },
                ),
                const Divider(thickness: 1, height: 0),  // Divider between image and title

                // Title of the marker (e.g., court name)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    title,  // Display the title text
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,  // Center-align the title
                  ),
                ),
                const Divider(thickness: 1, height: 0),  // Divider between title and ratings

                // Display ratings for Ring, Netz, and Platz categories
                _buildRatingSection("Ring", ringRating),   // Ring rating
                _buildRatingSection("Netz", netzRating),   // Netz rating
                _buildRatingSection("Platz", platzRating), // Platz rating

                // Button to add a rating
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0, top: 0),
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,  // Remove default padding
                      minimumSize: const Size(60, 30),  // Set minimum size for the button
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,  // Reduce touch target size
                    ),
                    onPressed: onAddRatingPressed,  // Trigger callback when pressed
                    icon: const Icon(Icons.star, color: Colors.orange),  // Star icon next to the text
                    label: const Text(
                      "Bewerte!",  // Label text for the button
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const Divider(thickness: 1, height: 0),  // Divider below the rating button

                // Show More Button (for viewing more details)
                GestureDetector(
                  onTap: onShowMorePressed,  // Trigger callback when pressed
                  child: const Padding(
                    padding: EdgeInsets.only(bottom: 5, top: 5),
                    child: Text(
                      'Mehr anzeigen',  // "Show More" text
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,  // Center-align the text
                    ),
                  ),
                ),
              ],
            ),
            // Close button at the top-right corner
            Positioned(
              right: 8,
              top: 8,
              child: GestureDetector(
                onTap: onClosePressed,  // Trigger callback when pressed
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,  // Circular shape for the close button
                    color: Colors.white.withOpacity(0.7),  // Semi-transparent background
                  ),
                  padding: const EdgeInsets.all(5),  // Padding inside the close button
                  child: const Icon(
                    Icons.close,  // Close icon
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
}
