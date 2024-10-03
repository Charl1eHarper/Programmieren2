import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';

class SearchWidget extends StatefulWidget {
  final bool isSearchVisible;
  final VoidCallback onSearchIconPressed;
  final GoogleMapController mapController;
  final Function(LatLng) onPlaceSelected;
  final FocusNode focusNode; // Focus node for handling search bar focus

  const SearchWidget({
    super.key,
    required this.isSearchVisible,
    required this.onSearchIconPressed,
    required this.mapController,
    required this.onPlaceSelected,
    required this.focusNode, // Initialize focus node
  });

  @override
  _SearchWidgetState createState() => _SearchWidgetState();
}

class _SearchWidgetState extends State<SearchWidget> {
  final TextEditingController _searchController = TextEditingController(); // Controller for managing search input
  List<Prediction> _placesList = []; // Holds the search results

  // Search for places using the Google Places API
  Future<void> _searchPlaces(String query) async {
    if (query.isEmpty) {
      setState(() {
        _placesList.clear(); // Clear results if query is empty
      });
      return;
    }

    GoogleMapsPlaces places = GoogleMapsPlaces(apiKey: 'AIzaSyB-Auv39s_lM1kjpfOBySaQwxTMq5kfY-o');
    PlacesAutocompleteResponse response = await places.autocomplete(query);

    if (response.isOkay) {
      setState(() {
        _placesList = response.predictions; // Display the search results
      });
    } else {
      setState(() {
        _placesList.clear(); // Clear results if the response is not OK
      });
    }
  }

  // Move the camera to the selected place and clear search results
  Future<void> _moveCameraToPlace(String placeId) async {
    GoogleMapsPlaces places = GoogleMapsPlaces(apiKey: 'AIzaSyB-Auv39s_lM1kjpfOBySaQwxTMq5kfY-o');
    PlacesDetailsResponse detail = await places.getDetailsByPlaceId(placeId);

    if (detail.isOkay) {
      final location = detail.result.geometry?.location;
      if (location != null) {
        LatLng selectedLocation = LatLng(location.lat, location.lng);
        widget.mapController.animateCamera(CameraUpdate.newLatLng(selectedLocation));

        setState(() {
          _searchController.text = detail.result.name; // Set the selected place name in the search bar
          _placesList.clear(); // Clear the search list after selection
        });

        widget.onPlaceSelected(selectedLocation); // Callback to indicate the selected place
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.isSearchVisible) // Show the search bar only when it's visible
          Container(
            height: 50,
            margin: const EdgeInsets.only(top: 0),
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
            ),
            child: Row(
              children: [
                // Search input field
                Expanded(
                  child: TextField(
                    controller: _searchController, // Link the input to the controller
                    focusNode: widget.focusNode, // Handle the focus state
                    onChanged: _searchPlaces, // Trigger search when text changes
                    decoration: const InputDecoration(
                      hintText: 'Search for courts...', // Placeholder text
                      border: InputBorder.none, // No border for the input field
                    ),
                  ),
                ),
                // Clear button
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear(); // Clear the input
                    _searchPlaces(''); // Reset the search results
                    widget.onSearchIconPressed(); // Close the search bar
                  },
                ),
              ],
            ),
          ),
        if (widget.isSearchVisible && _placesList.isNotEmpty) // Display results if there are places found
          Container(
            margin: const EdgeInsets.only(top: 5),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.25, // Limit the result box height
            ),
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(10),
              color: Colors.white,
              // Show search results as a list
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _placesList.length,
                itemBuilder: (context, index) {
                  final place = _placesList[index]; // Get the current place
                  return ListTile(
                    title: Text(place.description!), // Display the place description
                    onTap: () {
                      _moveCameraToPlace(place.placeId!); // Move the camera to the selected place
                    },
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}
