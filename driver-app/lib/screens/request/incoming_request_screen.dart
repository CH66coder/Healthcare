import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/request_card.dart';
import '../../providers/request_provider.dart';

class IncomingRequestScreen extends StatelessWidget {
  const IncomingRequestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final requestProvider = Provider.of<RequestProvider>(context);

    final lat = requestProvider.patientLat;
    final lng = requestProvider.patientLng;
    final locationText = (lat != null && lng != null)
        ? "Lat: ${lat.toStringAsFixed(5)}, Lng: ${lng.toStringAsFixed(5)}"
        : "Location unavailable";

    return Scaffold(
      appBar: AppBar(title: const Text("Incoming Emergency Request")),
      body: Center(
        child: requestProvider.requestStatus == "New Request"
            ? RequestCard(
                patientName: requestProvider.patientName ?? "",
                phone: requestProvider.patientPhone ?? "",
                location: locationText,
                emergency: requestProvider.patientEmergency ?? "", // added
                onAccept: () {
                  requestProvider.updateRequest("Accepted");
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Request Accepted")),
                  );
                },
                onReject: () {
                  requestProvider.updateRequest("Rejected");
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Request Rejected")),
                  );
                },
              )
            : const Text(
                "No Emergency Requests",
                style: TextStyle(fontSize: 18),
              ),
      ),
    );
  }
}
