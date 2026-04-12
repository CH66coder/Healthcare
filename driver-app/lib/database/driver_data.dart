class DriverData {
  // ← Changed 'drivers' list to single 'driver' map
  // so acceptRequest() can call DriverData.driver["driverName"]
  static Map<String, dynamic> driver = {
    "driverName": "Arun Kumar",
    "driverPhone": "9000000000",
    "ambulanceNumber": "TN01AB1234",
  };

  // Keep list for future multi-driver support
  static List<Map<String, dynamic>> drivers = [
    {
      "driverName": "Arun Kumar",
      "driverPhone": "9000000000",
      "ambulanceNumber": "TN01AB1234",
    },
    {
      "driverName": "Suresh Kumar",
      "driverPhone": "9111111111",
      "ambulanceNumber": "TN01CD5678",
    },
    {
      "driverName": "Ramesh Kumar",
      "driverPhone": "9222222222",
      "ambulanceNumber": "TN01EF9999",
    },
  ];
}
