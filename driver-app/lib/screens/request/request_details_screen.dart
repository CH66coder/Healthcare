import 'package:flutter/material.dart';
import '../../widgets/request_card.dart';

class IncomingRequestScreen extends StatelessWidget {
  const IncomingRequestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Incoming Emergency Request")),
      body: Center(
        child: RequestCard(
          patientName: "Ravi Kumar",
          phone: "9876543210",
          location: "Chennai Central",
          onAccept: () {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text("Request Accepted")));
          },
          onReject: () {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text("Request Rejected")));
          },
        ),
      ),
    );
  }
}
