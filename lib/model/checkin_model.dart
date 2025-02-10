class CheckinModel {
  final String clientId;
  final String email;
  final String password;
  final String attType;
  final String remarks;
  final double gpsLatitude;
  final double gpsLongitude;
  final String address;
  final String client;
  final String attTime;

  const CheckinModel({
    this.clientId = '',
    required this.email,
    required this.password,
    required this.remarks,
    required this.gpsLatitude,
    required this.gpsLongitude,
    required this.address,
    required this.attType,
    required this.attTime,
    required this.client,
  });
  toJson() {
    return {
      "client_id" : clientId,
      "remarks": remarks,
      "gps_latitude": gpsLatitude,
      "gps_longitude": gpsLongitude,
      "attendance_type": attType,
      "address": address,
      "client": client,
      "att_time": attTime,
    };
  }

  factory CheckinModel.fromJson(Map<String, dynamic> data) {
    return CheckinModel(
      clientId: data["client_id"],
      email: data["email"],
      password: data["password"],
      remarks: data["remarks"],
      gpsLatitude: data["gps_latitude"],
      gpsLongitude: data["gps_longitude"],
      attType: data["attendance_type"],
      address: data["address"],
      client: data["client"],
      attTime: data["att_time"],
    );
  }
}
