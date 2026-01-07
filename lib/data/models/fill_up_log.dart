class FillUpLog {
  final int? logId;
  final int vehicleId;
  final String date;
  final double distanceAtFilling;
  final double gasAdded;
  final double? feCalculated;

  FillUpLog({
    this.logId,
    required this.vehicleId,
    required this.date,
    required this.distanceAtFilling,
    required this.gasAdded,
    this.feCalculated,
  });

  Map<String, dynamic> toMap() {
    return {
      'logId': logId,
      'vehicleId': vehicleId,
      'date': date,
      'distanceAtFilling': distanceAtFilling,
      'gasAdded': gasAdded,
      'feCalculated': feCalculated,
    };
  }

  factory FillUpLog.fromMap(Map<String, dynamic> map) {
    return FillUpLog(
      logId: map['logId'] as int,
      vehicleId: map['vehicleId'] as int,
      date: map['date'] as String,
      distanceAtFilling: map['distanceAtFilling'] as double,
      gasAdded: map['gasAdded'] as double,
      feCalculated: map['feCalculated'] as double?,
    );
  }
}
