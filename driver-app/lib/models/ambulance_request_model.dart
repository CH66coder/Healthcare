class AmbulanceRequest {
  final String id;
  final String patientName;
  final String phone;
  final double latitude;
  final double longitude;
  final String status;

  AmbulanceRequest({
    required this.id,
    required this.patientName,
    required this.phone,
    required this.latitude,
    required this.longitude,
    required this.status,
  });

  factory AmbulanceRequest.fromMap(String id, Map<String, dynamic> data) {
    return AmbulanceRequest(
      id: id,
      patientName: data['patient_name'] ?? '', // fixed: was 'patientName'
      phone: data['phone'] ?? '',
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      status: data['status'] ?? 'pending', // fixed: was 'waiting'
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'patient_name': patientName,
      'phone': phone,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
    };
  }
}
