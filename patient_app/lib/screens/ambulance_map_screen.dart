import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/sos_service.dart';

class AmbulanceMapScreen extends StatefulWidget {
  const AmbulanceMapScreen({super.key});

  @override
  State<AmbulanceMapScreen> createState() =>
      _AmbulanceMapScreenState();
}

class _AmbulanceMapScreenState extends State<AmbulanceMapScreen> {
  GoogleMapController? mapController;
  LatLng? currentPosition;
  Set<Marker> markers = {};

  String? _requestId;
  StreamSubscription<DocumentSnapshot>? _driverListener;
  bool _driverPopupShown = false;
  bool _sosSent          = false;
  bool _driverAccepted   = false;
  String _driverName        = '';
  String _driverPhone       = '';
  String _ambulanceNumber   = '';

  static const Color _red    = Color(0xFFFF3B30);
  static const Color _bg     = Color(0xFF0D1117);
  static const Color _card   = Color(0xFF161B27);
  static const Color _border = Color(0xFF1E2A42);
  static const Color _green  = Color(0xFF00C896);
  static const Color _text2  = Color(0xFF8B9EC7);

  // ← Use the SAME key as standalone ambulance app
  final String _apiKey = "AIzaSyD253tRmBFax_-nY37Obo9wlPEvzZ2mIwA";

  String get _patientName =>
      FirebaseAuth.instance.currentUser?.displayName ?? 'Patient';
  String get _patientPhone =>
      FirebaseAuth.instance.currentUser?.phoneNumber ??
      FirebaseAuth.instance.currentUser?.email ?? '';

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  @override
  void dispose() {
    _driverListener?.cancel();
    super.dispose();
  }

  Future<void> _getUserLocation() async {
    try {
      bool serviceEnabled =
          await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              backgroundColor: _card,
              title: Text('Location Required',
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600)),
              content: Text(
                  'Please enable location services for SOS to work.',
                  style: GoogleFonts.poppins(
                      color: _text2)),
              actions: [
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await Geolocator.openLocationSettings();
                  },
                  child: Text('Open Settings',
                      style: GoogleFonts.poppins(
                          color: _green)),
                ),
              ],
            ),
          );
        }
        _useDefaultLocation();
        return;
      }

      LocationPermission permission =
          await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _useDefaultLocation();
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              backgroundColor: _card,
              title: Text('Permission Required',
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600)),
              content: Text(
                  'Location permission permanently denied. Please enable in app settings.',
                  style: GoogleFonts.poppins(
                      color: _text2)),
              actions: [
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await Geolocator.openAppSettings();
                  },
                  child: Text('Open Settings',
                      style: GoogleFonts.poppins(
                          color: _green)),
                ),
              ],
            ),
          );
        }
        _useDefaultLocation();
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high)
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;

      final LatLng userLocation =
          LatLng(position.latitude, position.longitude);

      setState(() {
        currentPosition = userLocation;
        markers.add(Marker(
          markerId:  const MarkerId("user"),
          position:  userLocation,
          infoWindow: InfoWindow(title: _patientName),
          icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed),
        ));
      });

      mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
            CameraPosition(target: userLocation, zoom: 15)),
      );

      _addNearbyAmbulances();
      await _getNearbyHospitals();
      await _sendSOS();
    } catch (e) {
      print('Location error: $e');
      _useDefaultLocation();
    }
  }

  void _useDefaultLocation() {
    const LatLng defaultLocation = LatLng(13.0827, 80.2707);
    if (!mounted) return;
    setState(() {
      currentPosition = defaultLocation;
      markers.add(Marker(
        markerId:  const MarkerId("user"),
        position:  defaultLocation,
        infoWindow: InfoWindow(title: _patientName),
        icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueRed),
      ));
    });
    _sendSOS();
  }

  void _addNearbyAmbulances() {
    if (currentPosition == null) return;
    setState(() {
      markers.add(Marker(
        markerId:  const MarkerId("ambulance1"),
        position: LatLng(
            currentPosition!.latitude + 0.003,
            currentPosition!.longitude + 0.003),
        infoWindow:
            const InfoWindow(title: "Ambulance Nearby"),
        icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueBlue),
      ));
      markers.add(Marker(
        markerId:  const MarkerId("ambulance2"),
        position: LatLng(
            currentPosition!.latitude - 0.003,
            currentPosition!.longitude - 0.002),
        infoWindow:
            const InfoWindow(title: "Ambulance Nearby"),
        icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueBlue),
      ));
    });
  }

  Future<void> _getNearbyHospitals() async {
    if (currentPosition == null) return;
    try {
      final url =
          "https://maps.googleapis.com/maps/api/place/nearbysearch/json"
          "?location=${currentPosition!.latitude},${currentPosition!.longitude}"
          "&radius=5000&type=hospital&key=$_apiKey";

      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) return;
      final data = json.decode(response.body);
      if (!mounted) return;

      setState(() {
        for (var place in data["results"] ?? []) {
          final lat  = place["geometry"]["location"]["lat"];
          final lng  = place["geometry"]["location"]["lng"];
          final name = place["name"];
          markers.add(Marker(
            markerId:  MarkerId(name),
            position:  LatLng(lat, lng),
            infoWindow: InfoWindow(title: name),
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueOrange),
          ));
        }
      });
    } catch (e) {
      print("Hospital loading error: $e");
    }
  }

  Future<void> _sendSOS() async {
    if (_sosSent) return;
    try {
      final requestId = await SOSService.sendSOS(
        name:      _patientName,
        phone:     _patientPhone,
        emergency: "Emergency SOS",
      );

      if (!mounted) return;
      setState(() => _sosSent = true);

      if (requestId != null) {
        _requestId        = requestId;
        _driverPopupShown = false;
        _listenForDriver(requestId);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('✅ SOS Sent! Waiting for driver...',
              style: GoogleFonts.poppins()),
          backgroundColor: _green,
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              '📵 Offline — SMS sent to driver!',
              style: GoogleFonts.poppins()),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
        ));
      }
    } catch (e) {
      print('SOS error: $e');
    }
  }

  void _listenForDriver(String requestId) {
    _driverListener = FirebaseFirestore.instance
        .collection("sos_requests")
        .doc(requestId)
        .snapshots()
        .listen((doc) {
      if (!doc.exists || !mounted) return;
      final data = doc.data()!;

      if (data['status'] == 'accepted' &&
          !_driverPopupShown) {
        _driverPopupShown = true;

        final driverName =
            data['driverName']      ?? 'Unknown';
        final driverPhone =
            data['driverPhone']     ?? 'Unknown';
        final ambulanceNumber =
            data['ambulanceNumber'] ?? 'Unknown';
        final driverLat =
            (data['driverLat'] as num?)?.toDouble();
        final driverLng =
            (data['driverLng'] as num?)?.toDouble();

        // Save driver info to state so banner stays
        setState(() {
          _driverAccepted  = true;
          _driverName      = driverName;
          _driverPhone     = driverPhone;
          _ambulanceNumber = ambulanceNumber;
        });

        if (driverLat != null && driverLng != null) {
          setState(() {
            markers.removeWhere(
                (m) => m.markerId.value == "assigned_ambulance");
            markers.add(Marker(
              markerId:
                  const MarkerId("assigned_ambulance"),
              position: LatLng(driverLat, driverLng),
              infoWindow: InfoWindow(
                  title:
                      "Your Ambulance: $ambulanceNumber"),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueGreen),
            ));
          });

          // Fit camera to show both
          if (currentPosition != null &&
              mapController != null) {
            final bounds = LatLngBounds(
              southwest: LatLng(
                driverLat < currentPosition!.latitude
                    ? driverLat
                    : currentPosition!.latitude,
                driverLng < currentPosition!.longitude
                    ? driverLng
                    : currentPosition!.longitude,
              ),
              northeast: LatLng(
                driverLat > currentPosition!.latitude
                    ? driverLat
                    : currentPosition!.latitude,
                driverLng > currentPosition!.longitude
                    ? driverLng
                    : currentPosition!.longitude,
              ),
            );
            mapController!.animateCamera(
                CameraUpdate.newLatLngBounds(bounds, 80));
          }
        }

        // Show popup — but map stays underneath
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => Dialog(
            alignment: Alignment.topCenter,
            insetPadding: const EdgeInsets.only(
                top: 60, left: 16, right: 16),
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: _green.withOpacity(0.4)),
                boxShadow: [
                  BoxShadow(
                    color:      _green.withOpacity(0.15),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color:  _green.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                        Icons.local_shipping_rounded,
                        color: _green,
                        size:  36),
                  ),
                  const SizedBox(height: 12),
                  Text('🚑 Ambulance Accepted!',
                      style: GoogleFonts.poppins(
                          color:      _green,
                          fontSize:   18,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('Help is on the way',
                      style: GoogleFonts.poppins(
                          color:    _text2,
                          fontSize: 13)),
                  const SizedBox(height: 16),
                  _infoRow(
                      Icons.person_outline_rounded,
                      'Driver', driverName),
                  const SizedBox(height: 8),
                  _infoRow(Icons.phone_outlined,
                      'Phone', driverPhone),
                  const SizedBox(height: 8),
                  _infoRow(
                      Icons.directions_car_outlined,
                      'Vehicle', ambulanceNumber),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _green,
                        padding:
                            const EdgeInsets.symmetric(
                                vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                                    12)),
                      ),
                      // ← Just closes popup, stays on map
                      onPressed: () =>
                          Navigator.pop(ctx),
                      child: Text('OK, Got It!',
                          style: GoogleFonts.poppins(
                              color:      Colors.white,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      // Live marker update as driver moves
      if (data['status'] == 'accepted') {
        final driverLat =
            (data['driverLat'] as num?)?.toDouble();
        final driverLng =
            (data['driverLng'] as num?)?.toDouble();
        final ambulanceNumber =
            data['ambulanceNumber'] ?? '';

        if (driverLat != null && driverLng != null) {
          setState(() {
            markers.removeWhere((m) =>
                m.markerId.value == "assigned_ambulance");
            markers.add(Marker(
              markerId:
                  const MarkerId("assigned_ambulance"),
              position: LatLng(driverLat, driverLng),
              infoWindow: InfoWindow(
                  title:
                      "Your Ambulance: $ambulanceNumber"),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueGreen),
            ));
          });
        }
      }
    });
  }

  Widget _infoRow(
      IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color:        const Color(0xFF1E2535),
        borderRadius: BorderRadius.circular(10),
        border:       Border.all(color: _border),
      ),
      child: Row(children: [
        Icon(icon, color: _green, size: 16),
        const SizedBox(width: 10),
        Text('$label: ',
            style: GoogleFonts.poppins(
                color: _text2, fontSize: 12)),
        Expanded(
          child: Text(value,
              style: GoogleFonts.poppins(
                  color:      Colors.white,
                  fontSize:   12,
                  fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (currentPosition == null) {
      return Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _red,
          title: Text('🚑 Emergency SOS',
              style: GoogleFonts.poppins(
                  color:      Colors.white,
                  fontWeight: FontWeight.w700)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back,
                color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                  color: _red),
              const SizedBox(height: 20),
              Text(
                'Getting your location\nand sending SOS...',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    color: Colors.white, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text('Please wait...',
                  style: GoogleFonts.poppins(
                      color: _text2, fontSize: 12)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: _red,
        title: Text(
          _driverAccepted
              ? '🚑 Ambulance Tracking'
              : (_sosSent
                  ? '📡 Finding Ambulance...'
                  : '🚨 Sending SOS...'),
          style: GoogleFonts.poppins(
              color:      Colors.white,
              fontSize:   16,
              fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back,
              color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_requestId != null)
            TextButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('sos_requests')
                    .doc(_requestId)
                    .update({'status': 'cancelled'});
                if (mounted) Navigator.pop(context);
              },
              child: Text('Cancel SOS',
                  style: GoogleFonts.poppins(
                      color:      Colors.white,
                      fontSize:   12,
                      fontWeight: FontWeight.w600)),
            ),
        ],
      ),
      body: Stack(
        children: [
          // ── Google Map ──────────────────────────
          GoogleMap(
            initialCameraPosition: CameraPosition(
                target: currentPosition!, zoom: 15),
            markers:                 markers,
            myLocationEnabled:       true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled:     true,
            mapType:                 MapType.normal,
            onMapCreated: (controller) {
              mapController = controller;
              controller.animateCamera(
                CameraUpdate.newCameraPosition(
                  CameraPosition(
                      target: currentPosition!,
                      zoom:   15),
                ),
              );
            },
          ),

          // ── Driver accepted banner — stays on screen
          if (_driverAccepted)
            Positioned(
              top:   10,
              left:  12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _card.withOpacity(0.97),
                  borderRadius:
                      BorderRadius.circular(16),
                  border: Border.all(
                      color: _green.withOpacity(0.5)),
                  boxShadow: [
                    BoxShadow(
                      color:      _green.withOpacity(0.2),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(children: [
                      Container(
                        padding:
                            const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _green.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                            Icons.local_shipping_rounded,
                            color: _green,
                            size:  22),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                                '🚑 Ambulance On The Way!',
                                style: GoogleFonts.poppins(
                                    color:      _green,
                                    fontSize:   13,
                                    fontWeight:
                                        FontWeight.w700)),
                            Text('Help is coming to you',
                                style: GoogleFonts.poppins(
                                    color:    _text2,
                                    fontSize: 11)),
                          ],
                        ),
                      ),
                    ]),
                    const SizedBox(height: 10),
                    _infoRow(
                        Icons.person_outline_rounded,
                        'Driver',
                        _driverName),
                    const SizedBox(height: 6),
                    _infoRow(Icons.phone_outlined,
                        'Phone', _driverPhone),
                    const SizedBox(height: 6),
                    _infoRow(
                        Icons.directions_car_outlined,
                        'Vehicle',
                        _ambulanceNumber),
                  ],
                ),
              ),
            ),

          // ── Bottom status card ──────────────────
          Positioned(
            bottom: 20,
            left:   12,
            right:  12,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _card.withOpacity(0.95),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _sosSent
                      ? _green.withOpacity(0.4)
                      : _red.withOpacity(0.4),
                ),
              ),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (_sosSent ? _green : _red)
                        .withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _sosSent
                        ? Icons.check_circle_rounded
                        : Icons.send_rounded,
                    color: _sosSent ? _green : _red,
                    size:  20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        _driverAccepted
                            ? 'Ambulance Dispatched ✅'
                            : (_sosSent
                                ? 'SOS Sent — Finding ambulance...'
                                : 'Sending SOS...'),
                        style: GoogleFonts.poppins(
                          color: _driverAccepted
                              ? _green
                              : (_sosSent
                                  ? _green
                                  : _red),
                          fontSize:   13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(_patientName,
                          style: GoogleFonts.poppins(
                              color:    _text2,
                              fontSize: 11)),
                    ],
                  ),
                ),
                if (_sosSent)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _red.withOpacity(0.15),
                      borderRadius:
                          BorderRadius.circular(20),
                    ),
                    child: Text('🔴 Active',
                        style: GoogleFonts.poppins(
                            color:      _red,
                            fontSize:   11,
                            fontWeight: FontWeight.w700)),
                  ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}