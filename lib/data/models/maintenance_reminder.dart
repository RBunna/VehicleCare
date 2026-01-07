class MaintenanceReminder {
  final int? reminderId;
  final int vehicleId;
  final String serviceType;
  final IntervalType intervalType;
  final double intervalValue;
  final double lastTriggerOdometer;
  final String lastTriggerDate;

  MaintenanceReminder({
    this.reminderId,
    required this.vehicleId,
    required this.serviceType,
    required this.intervalType,
    required this.intervalValue,
    required this.lastTriggerOdometer,
    required this.lastTriggerDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'reminderId': reminderId,
      'vehicleId': vehicleId,
      'serviceType': serviceType,
      'intervalType': intervalType.name,
      'intervalValue': intervalValue,
      'lastTriggerOdometer': lastTriggerOdometer,
      'lastTriggerDate': lastTriggerDate,
    };
  }

  factory MaintenanceReminder.fromMap(Map<String, dynamic> map) {
    final String typeString = map['intervalType'] as String;
    return MaintenanceReminder(
      reminderId: map['reminderId'] as int,
      vehicleId: map['vehicleId'] as int,
      serviceType: map['serviceType'] as String,
      intervalType: IntervalType.values.byName(typeString),
      intervalValue: map['intervalValue'] as double,
      lastTriggerOdometer: map['lastTriggerOdometer'] as double,
      lastTriggerDate: map['lastTriggerDate'] as String,
    );
  }
}

enum IntervalType { distance, time }
