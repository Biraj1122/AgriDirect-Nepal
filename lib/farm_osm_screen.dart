import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import 'location_service.dart';

class FarmOsmScreen extends StatefulWidget {
  const FarmOsmScreen({super.key});

  @override
  State<FarmOsmScreen> createState() =>
      _FarmOsmScreenState();
}

class _FarmOsmScreenState
    extends State<FarmOsmScreen> {

  GoogleMapController? mapController;

  final LocationService locationService =
  LocationService();

  StreamSubscription<Position>?
  positionStream;

  LatLng currentPosition =
  const LatLng(
    27.7172,
    85.3240,
  );

  bool loading = true;

  Set<Marker> markers = {};

  @override
  void initState() {
    super.initState();
    initializeLocation();
  }

  Future<void> initializeLocation() async {

    bool granted =
    await locationService
        .requestPermission();

    if (!granted) {

      setState(() {
        loading = false;
      });

      return;
    }

    positionStream =
        locationService
            .getLiveLocation()
            .listen((Position position) {

          LatLng newLocation = LatLng(
            position.latitude,
            position.longitude,
          );

          setState(() {

            currentPosition =
                newLocation;

            markers = {

              Marker(
                markerId:
                const MarkerId(
                    "current"),

                position:
                newLocation,
              )
            };

            loading = false;
          });

          mapController?.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target:
                newLocation,
                zoom: 18,
                tilt: 45,
              ),
            ),
          );

        });
  }

  void moveCurrentLocation() {

    mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        currentPosition,
        18,
      ),
    );
  }

  @override
  void dispose() {

    positionStream?.cancel();

    super.dispose();
  }

  @override
  Widget build(
      BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title:
        const Text(
            "Live Map"),
        backgroundColor:
        Colors.green,
      ),

      body: loading
          ? const Center(
        child:
        CircularProgressIndicator(),
      )
          : Stack(

        children: [

          GoogleMap(

            initialCameraPosition:
            CameraPosition(
              target:
              currentPosition,
              zoom: 18,
            ),

            myLocationEnabled:
            true,

            myLocationButtonEnabled:
            false,

            zoomControlsEnabled:
            false,

            markers:
            markers,

            onMapCreated:
                (controller) {

              mapController =
                  controller;
            },
          ),

          Positioned(

            right: 16,
            bottom: 120,

            child:
            FloatingActionButton(

              backgroundColor:
              Colors.white,

              onPressed:
              moveCurrentLocation,

              child:
              const Icon(
                Icons.my_location,
                color:
                Colors.black,
              ),
            ),
          )
        ],
      ),
    );
  }
}
