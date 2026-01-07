import 'package:sqflite/sqflite.dart';
import 'package:vehicle_care/data/db/app_database.dart';
import 'package:vehicle_care/data/models/maintenance_reminder.dart';

class ReminderRepository {
  final Database db;

  ReminderRepository(this.db);

  // --- CREATE ---
  Future<int> createReminder(MaintenanceReminder reminder) async {
    return await db.insert(tableMaintenanceReminder, reminder.toMap());
  }

  // --- READ ---
  Future<List<MaintenanceReminder>> getRemindersByVehicle(int vehicleId) async {
    final List<Map<String, dynamic>> maps = await db.query(
      tableMaintenanceReminder,
      where: 'vehicleId = ?',
      whereArgs: [vehicleId],
    );
    return maps.map((map) => MaintenanceReminder.fromMap(map)).toList();
  }

  // --- UPDATE ---
  Future<int> updateReminderTrigger(int reminderId, double newOdo, String newDate) async {
    return await db.update(
      tableMaintenanceReminder,
      {
        'lastTriggerOdometer': newOdo,
        'lastTriggerDate': newDate,
      },
      where: 'reminderId = ?',
      whereArgs: [reminderId],
    );
  }
}