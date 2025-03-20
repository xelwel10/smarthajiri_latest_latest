class DeviceModel {
  final String brand;
  final String model;
  final String id;

  const DeviceModel({
    required this.brand,
    required this.model,
    required this.id,
  });
  toJson() {
    return {
      "brand": brand,
      "model": model,
      "id": id,
    };
  }

  Map<String, dynamic> fromJson(DeviceModel info) => <String, dynamic>{
        'brand': info.brand,
        'model': info.model,
        'id': info.id,
      };
}
