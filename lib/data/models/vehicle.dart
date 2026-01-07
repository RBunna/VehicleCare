import 'package:vehicle_care/services/calculators/fe_calculator.dart';
import 'package:vehicle_care/services/managers/reminder_manager.dart';

class Vehicle {
  final int? vehicleId;

  final String nickname;
  final double initialOdometer;

  final String? photoPath;
  final String? makeModel;
  final String? licensePlate;

  final double? avgFe;

  final MaintenanceStatus maintenanceStatus;
  final FeStatus feVarianceStatus;

  Vehicle({
    this.vehicleId,
    required this.nickname,
    this.photoPath,
    this.makeModel,
    this.licensePlate,
    required this.initialOdometer,
    this.avgFe,

    this.maintenanceStatus = MaintenanceStatus.ok,
    this.feVarianceStatus = FeStatus.ok,
  });

  Map<String, dynamic> toMap() {
    return {
      'vehicleId': vehicleId,
      'nickname': nickname,
      'photoPath': photoPath,
      'makeModel': makeModel,
      'licensePlate': licensePlate,
      'initialOdometer': initialOdometer,
      'avgFe': avgFe,
    };
  }

  factory Vehicle.fromMap(Map<String, dynamic> map) {
    return Vehicle(
      vehicleId: map['vehicleId'] as int,
      nickname: map['nickname'] as String,
      photoPath: map['photoPath'] as String?,
      makeModel: map['makeModel'] as String?,
      licensePlate: map['licensePlate'] as String?,
      initialOdometer: map['initialOdometer'] as double,
      avgFe: map['avgFe'] as double?,
    );
  }

  Vehicle copyWith({
    double? avgFe,
    MaintenanceStatus? maintenanceStatus,
    FeStatus? feVarianceStatus,
  }) {
    return Vehicle(
      vehicleId: vehicleId,
      nickname: nickname,
      photoPath: photoPath,
      makeModel: makeModel,
      licensePlate: licensePlate,
      initialOdometer: initialOdometer,

      avgFe: avgFe ?? this.avgFe,

      maintenanceStatus: maintenanceStatus ?? this.maintenanceStatus,
      feVarianceStatus: feVarianceStatus ?? this.feVarianceStatus,
    );
  }
}
