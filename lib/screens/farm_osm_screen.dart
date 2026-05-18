import 'package:flutter/material.dart';
import 'package:osm_search_and_pick/open_street_map_search_and_pick.dart';

class FarmOsmScreen extends StatelessWidget {
  const FarmOsmScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Location'),
        backgroundColor: const Color(0xFF0F9D58),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: OpenStreetMapSearchAndPick(
        hintText: 'Search place name or address...',
        buttonColor: const Color(0xFF0F9D58),
        buttonText: 'Confirm Selection',
        onPicked: (pickedData) {
          // Returning structured parameters to updating state screens
          Navigator.pop(context, {
            'lat': pickedData.latLong.latitude,
            'lng': pickedData.latLong.longitude,
            'address': pickedData.addressName,
          });
        },
      ),
    );
  }
}