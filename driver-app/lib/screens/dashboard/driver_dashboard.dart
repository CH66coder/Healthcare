import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/driver_status_toggle.dart';
import '../../widgets/map_widget.dart';
import '../../providers/request_provider.dart';

class DriverDashboard extends StatefulWidget {
  const DriverDashboard({super.key});

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  bool _dialogShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final requestProvider = Provider.of<RequestProvider>(
        context,
        listen: false,
      );

      requestProvider.addListener(() {
        if (requestProvider.requestStatus == "New Request" && !_dialogShown) {
          _dialogShown = true;
          _showRequestDialog(requestProvider);
        }
        if (requestProvider.requestStatus == "No Request") {
          _dialogShown = false;
        }
      });
    });
  }

  void _showRequestDialog(RequestProvider requestProvider) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "🚨 Emergency Request!",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 12),
              _infoRow("Patient", requestProvider.patientName ?? ''),
              _infoRow("Phone", requestProvider.patientPhone ?? ''),
              _infoRow(
                "Emergency",
                requestProvider.patientEmergency ?? '',
              ), // added
              _infoRow(
                "Lat",
                requestProvider.patientLat?.toStringAsFixed(5) ?? '',
              ),
              _infoRow(
                "Lng",
                requestProvider.patientLng?.toStringAsFixed(5) ?? '',
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      requestProvider.updateRequest("Accepted");
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Request Accepted")),
                      );
                    },
                    child: const Text(
                      "Accept",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      requestProvider.updateRequest("Rejected");
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Request Rejected")),
                      );
                    },
                    child: const Text(
                      "Reject",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).then((_) => _dialogShown = false);
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Driver Dashboard")),
      body: Column(
        children: [
          const SizedBox(height: 10),
          const DriverStatusToggle(),
          const SizedBox(height: 10),
          const Expanded(child: MapWidget()),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, "/incoming-request");
            },
            child: const Text("Test Emergency Request"),
          ),
          const SizedBox(height: 15),
        ],
      ),
    );
  }
}
