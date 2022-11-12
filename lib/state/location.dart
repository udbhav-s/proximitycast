import "dart:async";
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:location/location.dart';

class LocationManager extends AsyncNotifier<LocationData> {
  Location location = Location();

  @override
  Future<LocationData> build() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;
    LocationData locationData;

    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        throw Exception("Location service not enabled!");
      }
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        throw Exception("Location permission not given!");
      }
    }

    locationData = await location.getLocation();

    location.onLocationChanged.listen((LocationData currentLocation) {
      state = AsyncValue.data(currentLocation);
    });

    return locationData;
  }
}

final locationProvider = AsyncNotifierProvider<LocationManager, LocationData>(
  LocationManager.new
);