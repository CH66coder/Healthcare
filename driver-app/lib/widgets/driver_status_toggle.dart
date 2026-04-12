import 'package:flutter/material.dart';

class DriverStatusToggle extends StatefulWidget {
  const DriverStatusToggle({super.key});

  @override
  State<DriverStatusToggle> createState() => _DriverStatusToggleState();
}

class _DriverStatusToggleState extends State<DriverStatusToggle> {

  bool isOnline = false;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [

        const Text("Offline"),

        Switch(
          value: isOnline,
          onChanged: (value) {
            setState(() {
              isOnline = value;
            });
          },
        ),

        const Text("Online")

      ],
    );
  }
}