import 'package:flutter/material.dart';

class DriverProvider extends ChangeNotifier {

  String driverName = "Driver";

  void updateDriver(String name) {
    driverName = name;
    notifyListeners();
  }

}