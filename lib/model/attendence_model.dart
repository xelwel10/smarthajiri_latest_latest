class AttendanceModel {
  final String email;
  final String password;
  final String attType;
  final String remarks;
  final double gpsLatitude;
  final double gpsLongitude;
  final String address;

  const AttendanceModel({
    required this.email,
    required this.password,
    required this.remarks,
    required this.gpsLatitude,
    required this.gpsLongitude,
    required this.address,
    required this.attType,
  });
  toJson() {
    return {
      "email": email,
      "password": password,
      "remarks": remarks,
      "gps_latitude": gpsLatitude,
      "gps_longitude": gpsLongitude,
      "att_type": attType,
      "address": address,
    };
  }

  factory AttendanceModel.fromJson(Map<String, dynamic> data) {
    return AttendanceModel(
      email: data["email"],
      password: data["password"],
      remarks: data["remarks"],
      gpsLatitude: data["gps_latitude"],
      gpsLongitude: data["gps_longitude"],
      attType: data["att_type"],
      address: data["address"],
    );
  }
}
