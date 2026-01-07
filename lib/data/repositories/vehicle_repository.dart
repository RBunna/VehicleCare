import 'package:sqflite/sqflite.dart';
import 'package:vehicle_care/data/db/app_database.dart';
import 'package:vehicle_care/data/models/vehicle.dart';
import 'package:vehicle_care/data/repositories/log_repository.dart';
import 'package:vehicle_care/data/repositories/reminder_repository.dart';
import 'package:vehicle_care/services/calculators/fe_calculator.dart';
import 'package:vehicle_care/services/managers/reminder_manager.dart';

class VehicleRepository {
  final Database db;

  VehicleRepository(this.db);

  Future<int> createVehicle(Vehicle vehicle) async {
    return await db.insert(
      tableVehicle,
      vehicle.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Vehicle>> getAllVehiclesWithMetrics() async {
    final List<Map<String, dynamic>> maps = await db.query(tableVehicle);
    final vehicles = maps.map((map) => Vehicle.fromMap(map)).toList();

    for (var vehicle in vehicles) {
      if (vehicle.vehicleId != null) {
        final logRepo = LogRepository(db);

        final maintenanceStatus = await ReminderManager(
          ReminderRepository(db),
          logRepo,
        ).getMostSevereStatus(vehicle.vehicleId!);

        FeStatus feStatus = FeStatus.ok;
        final FE_VarianceResult fe_varianceResult = await FECalculator(
          logRepo,
          this,
        ).calculateAndSaveVariance(vehicle.vehicleId!);
        if (fe_varianceResult.isSignificantAlert) {
          feStatus = FeStatus.green;
        } else if (fe_varianceResult.isNegative) {
          feStatus = FeStatus.red;
        }

        final updatedVehicle = vehicle.copyWith(
          maintenanceStatus: maintenanceStatus,
          feVarianceStatus: feStatus,
        );

        vehicles[vehicles.indexOf(vehicle)] = updatedVehicle;
      }
    }
    return vehicles;
  }

  Future<Vehicle?> getVehicleById(int vehicleId) async {
    final List<Map<String, dynamic>> maps = await db.query(
      tableVehicle,
      where: 'vehicleId = ?',
      whereArgs: [vehicleId],
    );
    if (maps.isNotEmpty) {
      return Vehicle.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateVehicleAvgFE(int vehicleId, double newAvgFE) async {
    return await db.update(
      tableVehicle,
      {'avgFe': newAvgFE},
      where: 'vehicleId = ?',
      whereArgs: [vehicleId],
    );
  }

  Future<void> deleteVehicle(int vehicleId) async {
    await db.delete(
      tableVehicle,
      where: 'vehicleId = ?',
      whereArgs: [vehicleId],
    );
  }
}
