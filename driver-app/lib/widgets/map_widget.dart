import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/location_provider.dart';
import '../providers/request_provider.dart';

class MapWidget extends StatefulWidget {
  const MapWidget({super.key});

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  GoogleMapController? mapController;

  LatLng? ambulanceLocation;
  LatLng? patientLocation;

  Set<Marker> markers = {};
  Set<Polyline> polylines = {};

  bool _listeningToRequest = false;

  final LatLng _defaultCenter = const LatLng(13.0827, 80.2707);

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final locationProvider = Provider.of<LocationProvider>(
        context,
        listen: false,
      );
      locationProvider.addListener(_onLocationUpdated);

      final requestProvider = Provider.of<RequestProvider>(
        context,
        listen: false,
      );

      // If request already exists when widget loads
      if (requestProvider.requestId != null && !_listeningToRequest) {
        _listeningToRequest = true;
        _listenToRequest(requestProvider.requestId!);
      }

      // Watch for requestId changes
      requestProvider.addListener(() {
        if (requestProvider.requestId != null && !_listeningToRequest) {
          _listeningToRequest = true;
          _listenToRequest(requestProvider.requestId!);
        }

        // Reset everything when request is cleared
        if (requestProvider.requestId == null) {
          _listeningToRequest = false;
          setState(() {
            markers = {};
            polylines = {};
            ambulanceLocation = null;
            patientLocation = null;
          });
        }
      });
    });
  }

  void _listenToRequest(String requestId) {
    print("MAP: Starting Firestore listener for requestId=$requestId");

    FirebaseFirestore.instance
        .collection("sos_requests")
        .doc(requestId)
        .snapshots()
        .listen((doc) {
          if (!doc.exists) return;
          final data = doc.data()!;

          // Ignore completed or rejected requests
          final status = data['status'] ?? '';
          if (status == 'completed' || status == 'rejected') {
            setState(() {
              markers = {};
              polylines = {};
              ambulanceLocation = null;
              patientLocation = null;
            });
            return;
          }

          final double? pLat = (data['latitude'] as num?)?.toDouble();
          final double? pLng = (data['longitude'] as num?)?.toDouble();
          final double? dLat = (data['driverLat'] as num?)?.toDouble();
          final double? dLng = (data['driverLng'] as num?)?.toDouble();

          if (pLat != null && pLng != null) {
            patientLocation = LatLng(pLat, pLng);
          }

          // Only set ambulance location if real non-zero coords
          if (dLat != null && dLng != null && dLat != 0 && dLng != 0) {
            ambulanceLocation = LatLng(dLat, dLng);
          }

          _updateMarkers();
          _fitBounds();
        });
  }

  void _onLocationUpdated() {
    final locationProvider = Provider.of<LocationProvider>(
      context,
      listen: false,
    );

    // Only update if real position
    if (locationProvider.latitude == 0 && locationProvider.longitude == 0) {
      return;
    }

    ambulanceLocation = LatLng(
      locationProvider.latitude,
      locationProvider.longitude,
    );

    _updateMarkers();
    _fitBounds();
  }

  void _updateMarkers() {
    setState(() {
      markers = {};
      polylines = {};

      if (ambulanceLocation != null) {
        markers.add(
          Marker(
            markerId: const MarkerId("ambulance"),
            position: ambulanceLocation!,
            infoWindow: const InfoWindow(title: "Ambulance"),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueBlue,
            ),
          ),
        );
      }

      if (patientLocation != null) {
        markers.add(
          Marker(
            markerId: const MarkerId("patient"),
            position: patientLocation!,
            infoWindow: const InfoWindow(title: "Patient"),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
          ),
        );
      }

      // Draw line only when both markers exist
      if (ambulanceLocation != null && patientLocation != null) {
        polylines.add(
          Polyline(
            polylineId: const PolylineId("route"),
            color: Colors.black,
            width: 6,
            geodesic: true,
            points: [ambulanceLocation!, patientLocation!],
          ),
        );
      }
    });
  }

  void _fitBounds() {
    if (mapController == null) return;
    if (ambulanceLocation == null) return;
    if (patientLocation == null) return;

    final bounds = LatLngBounds(
      southwest: LatLng(
        ambulanceLocation!.latitude < patientLocation!.latitude
            ? ambulanceLocation!.latitude
            : patientLocation!.latitude,
        ambulanceLocation!.longitude < patientLocation!.longitude
            ? ambulanceLocation!.longitude
            : patientLocation!.longitude,
      ),
      northeast: LatLng(
        ambulanceLocation!.latitude > patientLocation!.latitude
            ? ambulanceLocation!.latitude
            : patientLocation!.latitude,
        ambulanceLocation!.longitude > patientLocation!.longitude
            ? ambulanceLocation!.longitude
            : patientLocation!.longitude,
      ),
    );

    mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
  }

  void onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  void dispose() {
    final locationProvider = Provider.of<LocationProvider>(
      context,
      listen: false,
    );
    locationProvider.removeListener(_onLocationUpdated);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      onMapCreated: onMapCreated,
      initialCameraPosition: CameraPosition(target: _defaultCenter, zoom: 13),
      markers: markers,
      polylines: polylines,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
    );
  }
}
