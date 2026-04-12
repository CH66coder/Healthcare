import 'package:geolocator/geolocator.dart';

class Permissions {

  static Future<void> requestLocationPermission() async {

    LocationPermission permission = await Geolocator.requestPermission();

    if (permission == LocationPermission.denied) {
      throw Exception("Location permission denied");
    }

  }

}