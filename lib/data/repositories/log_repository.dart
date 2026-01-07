import 'package:sqflite/sqflite.dart';
import 'package:vehicle_care/data/db/app_database.dart';
import 'package:vehicle_care/data/models/fill_up_log.dart';
import 'package:vehicle_care/data/models/maintenance_log.dart';

class LogRepository {
  final Database db;

  LogRepository(this.db);

  // --- FILL-UP LOGS ---
  Future<int> createFillUpLog(FillUpLog log) async {
    return await db.insert(tableFillUpLog, log.toMap());
  }

  Future<FillUpLog?> getLastFillUpLog(int vehicleId) async {
    final List<Map<String, dynamic>> maps = await db.query(
      tableFillUpLog,
      where: 'vehicleId = ?',
      whereArgs: [vehicleId],
      orderBy: 'distanceAtFilling DESC', 
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return FillUpLog.fromMap(maps.first);
    }
    return null;
  }

  Future<List<FillUpLog>> getFillUpLogsByVehicle(int vehicleId) async {
    final List<Map<String, dynamic>> maps = await db.query(
      tableFillUpLog,
      where: 'vehicleId = ?',
      whereArgs: [vehicleId],
      orderBy: 'date DESC',
    );
    return maps.map((map) => FillUpLog.fromMap(map)).toList();
  }

  // --- MAINTENANCE LOGS ---
  Future<int> createMaintenanceLog(MaintenanceLog log) async {
    return await db.insert(tableMaintenanceLog, log.toMap());
  }

  Future<List<MaintenanceLog>> getMaintenanceLogsByVehicle(int vehicleId) async {
    final List<Map<String, dynamic>> maps = await db.query(
      tableMaintenanceLog,
      where: 'vehicleId = ?',
      whereArgs: [vehicleId],
      orderBy: 'date DESC',
    );
    return maps.map((map) => MaintenanceLog.fromMap(map)).toList();
  }
}