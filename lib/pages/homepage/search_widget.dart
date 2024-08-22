import 'package:flutter/material.dart';
import 'package:google_maps_webservice/places.dart';

class SearchWidget extends StatefulWidget {
  final bool isSearchVisible;
  final VoidCallback onSearchIconPressed;

  const SearchWidget({
    super.key,
    required this.isSearchVisible,
    required this.onSearchIconPressed,
  });

  @override
  _SearchWidgetState createState() => _SearchWidgetState();
}

class _SearchWidgetState extends State<SearchWidget> {
  final TextEditingController _searchController = TextEditingController();
  List<Prediction> _placesList = [];

  Future<void> _searchPlaces(String query) async {
    if (query.isEmpty) {
      setState(() {
        _placesList.clear();
      });
      return;
    }

    GoogleMapsPlaces places = GoogleMapsPlaces(apiKey: 'YOUR_API_KEY_HERE');
    PlacesAutocompleteResponse response = await places.autocomplete(query);

    if (response.isOkay) {
      setState(() {
        _placesList = response.predictions;
      });
    } else {
      setState(() {
        _placesList.clear();
      });
    }
  }

  Future<void> _moveCameraToPlace(String placeId) async {
    GoogleMapsPlaces places = GoogleMapsPlaces(apiKey: 'YOUR_API_KEY_HERE');
    PlacesDetailsResponse detail = await places.getDetailsByPlaceId(placeId);

    if (detail.isOkay) {
      final location = detail.result.geometry?.location;
      if (location != null) {
        // Hier den MapController verwenden, um die Kamera zu bewegen
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.center,
          child: Container(
            width: 350,
            height: 55,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(35),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.search, color: Colors.black, size: 40),
                  onPressed: widget.onSearchIconPressed,
                ),
                IconButton(
                  icon: const Icon(Icons.people, color: Colors.black, size: 40),
                  onPressed: () {
                    Navigator.pushNamed(context, '/community');
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.account_circle,
                      color: Colors.black, size: 40),
                  onPressed: () {
                    // Action for account button
                  },
                ),
              ],
            ),
          ),
        ),
        if (widget.isSearchVisible)
          Container(
            width: 350,
            margin: const EdgeInsets.symmetric(vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _searchPlaces,
              decoration: InputDecoration(
                hintText: 'Search for places...',
                border: InputBorder.none,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _searchPlaces('');
                  },
                ),
              ),
            ),
          ),
        if (widget.isSearchVisible && _placesList.isNotEmpty)
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              width: 350,
              margin: const EdgeInsets.only(top: 190),
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(10),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _placesList.length,
                  itemBuilder: (context, index) {
                    final place = _placesList[index];
                    return ListTile(
                      title: Text(place.description!),
                      onTap: () {
                        _moveCameraToPlace(place.placeId!);
                        setState(() {
                          _placesList.clear();
                        });
                      },
                    );
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }
}
