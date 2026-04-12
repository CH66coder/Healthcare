import 'package:flutter/material.dart';

class RequestCard extends StatelessWidget {
  final String patientName;
  final String phone;
  final String location;
  final String emergency; // added
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const RequestCard({
    super.key,
    required this.patientName,
    required this.phone,
    required this.location,
    required this.emergency, // added
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      margin: const EdgeInsets.all(20),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "🚑 Emergency Request",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 15),
            Text("Patient: $patientName"),
            Text("Phone: $phone"),
            Text("Emergency: $emergency"), // added
            Text("Location: $location"),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  onPressed: onAccept,
                  child: const Text("Accept"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: onReject,
                  child: const Text("Reject"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
