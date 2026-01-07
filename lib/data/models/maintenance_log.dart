class MaintenanceLog {
  final int? maintenanceId;
  final int vehicleId; 
  final String date;
  final String serviceType;
  final double odometer;

  MaintenanceLog({
    this.maintenanceId,
    required this.vehicleId,
    required this.date,
    required this.serviceType,
    required this.odometer,
  });

  Map<String, dynamic> toMap() {
    return {
      'maintenanceId': maintenanceId,
      'vehicleId': vehicleId,
      'date': date,
      'serviceType': serviceType,
      'odometer': odometer,
    };
  }

  factory MaintenanceLog.fromMap(Map<String, dynamic> map) {
    return MaintenanceLog(
      maintenanceId: map['maintenanceId'] as int,
      vehicleId: map['vehicleId'] as int,
      date: map['date'] as String,
      serviceType: map['serviceType'] as String,
      odometer: map['odometer'] as double,
    );
  }
}