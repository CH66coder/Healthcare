import 'package:flutter/material.dart';

import '../screens/auth/login_screen.dart';
import '../screens/dashboard/driver_dashboard.dart';
import '../screens/request/incoming_request_screen.dart';

class AppRoutes {

  static const String login = "/";
  static const String dashboard = "/dashboard";
  static const String incomingRequest = "/incoming-request";

  static Map<String, WidgetBuilder> routes = {

    login: (context) => const LoginScreen(),

    dashboard: (context) => const DriverDashboard(),

    incomingRequest: (context) => const IncomingRequestScreen(),

  };

}