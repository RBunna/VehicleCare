import 'package:vehicle_care/data/models/maintenance_log.dart';
import 'package:vehicle_care/data/repositories/reminder_repository.dart';
import 'package:vehicle_care/data/repositories/log_repository.dart';
import 'package:vehicle_care/data/models/maintenance_reminder.dart';

// Placeholder class/enum definitions needed for compilation sanity
enum IntervalType { distance, time }

class ReminderStatus {
  final String serviceType;
  final double value; // Remaining distance or time (can be negative if overdue)
  final ReminderUnit unit; // 'km', or 'months'
  final MaintenanceStatus status;

  ReminderStatus({
    required this.serviceType,
    required this.value,
    required this.unit,
    required this.status,
  });
}

enum ReminderUnit { km, months, na }

enum MaintenanceStatus { critical, warning, ok }

class ReminderManager {
  final ReminderRepository reminderRepo;
  final LogRepository logRepo;

  ReminderManager(this.reminderRepo, this.logRepo);

  // --- Main Execution Method (Called by Detail Screen) ---
  Future<List<ReminderStatus>> checkAllReminders(int vehicleId) async {
    final reminders = await reminderRepo.getRemindersByVehicle(vehicleId);

    // Get the absolute latest odometer for the prediction. Use null-aware coalescing.
    final latestLog = await logRepo.getLastFillUpLog(vehicleId);
    final latestOdo = latestLog?.distanceAtFilling ?? 0.0;

    return reminders.map((r) => _processSingleReminder(r, latestOdo)).toList();
  }

  Future<MaintenanceStatus> getMostSevereStatus(int vehicleId) async {
    List<ReminderStatus> statuses = await checkAllReminders(vehicleId);
    MaintenanceStatus mostSevere = MaintenanceStatus.ok;
    for (ReminderStatus s in statuses) {
      if (s.status == MaintenanceStatus.critical) {
        mostSevere = MaintenanceStatus.critical;
        break;
      } else if (s.status == MaintenanceStatus.warning &&
          mostSevere == MaintenanceStatus.ok) {
        mostSevere = MaintenanceStatus.warning;
      }
    }
    return mostSevere;
  }

  ReminderStatus _processSingleReminder(
    MaintenanceReminder reminder,
    double latestOdo,
  ) {
    const double distanceBuffer = 500.0;
    const double timeBufferMonths = 1.0;

    MaintenanceStatus status = MaintenanceStatus.ok;
    ReminderUnit resultUnit = ReminderUnit.na;
    double remainingValue = 0.0;

    if (reminder.intervalType == IntervalType.distance) {
      resultUnit = ReminderUnit.km;

      final distanceSinceLastService = latestOdo - reminder.lastTriggerOdometer;
      remainingValue = reminder.intervalValue - distanceSinceLastService;

      if (remainingValue <= 0) {
        status = MaintenanceStatus.critical;
      } else if (remainingValue <= distanceBuffer) {
        status = MaintenanceStatus.warning;
      }

      return ReminderStatus(
        serviceType: reminder.serviceType,
        value: remainingValue.abs(),
        unit: resultUnit,
        status: status,
      );
    } else if (reminder.intervalType == IntervalType.time) {
      resultUnit = ReminderUnit.months;

      // FIX: Check for null/empty date string before parsing
      if (reminder.lastTriggerDate.isEmpty) {
        // Cannot calculate time elapsed without a last trigger date
        return ReminderStatus(
          serviceType: reminder.serviceType,
          value: 0.0,
          unit: ReminderUnit.months,
          status: MaintenanceStatus.ok,
        );
      }

      final lastDate = DateTime.parse(
        reminder.lastTriggerDate,
      ); // Safe cast after null check
      final currentDate = DateTime.now();

      final monthsElapsed =
          (currentDate.year - lastDate.year) * 12 +
          currentDate.month -
          lastDate.month;

      remainingValue = reminder.intervalValue - monthsElapsed;

      if (remainingValue <= 0) {
        status = MaintenanceStatus.critical;
      } else if (remainingValue <= timeBufferMonths) {
        status = MaintenanceStatus.warning;
      }

      return ReminderStatus(
        serviceType: reminder.serviceType,
        value: remainingValue.abs(),
        unit: resultUnit,
        status: status,
      );
    }

    // Default case for safety
    return ReminderStatus(
      serviceType: reminder.serviceType,
      value: 0.0,
      unit: ReminderUnit.na,
      status: MaintenanceStatus.ok,
    );
  }

  // --- Action Method ---
  Future<void> logServiceComplete(
    MaintenanceReminder reminder,
    double currentOdo,
    DateTime currentDate,
  ) async {
    final formattedDate = currentDate.toIso8601String().substring(0, 10);
    final reminderId = reminder.reminderId;

    // FIX 2: Check if reminderId is null before proceeding
    if (reminderId == null) {
      // If the ID is null, we cannot update the reminder; log the log entry but skip update.
      // A data integrity warning might be appropriate in a production app.
      print(
        "Warning: Cannot update reminder trigger point. Reminder ID is null for service: ${reminder.serviceType}",
      );
    }

    // 1. Create the historical record (MaintenanceLog)
    final newLog = MaintenanceLog(
      vehicleId: reminder.vehicleId,
      date: formattedDate,
      serviceType: reminder.serviceType,
      odometer: currentOdo,
    );
    await logRepo.createMaintenanceLog(newLog);

    // 2. Update the reminder's trigger points for the next prediction
    if (reminderId != null) {
      await reminderRepo.updateReminderTrigger(
        reminderId, // Now non-nullable
        currentOdo,
        formattedDate,
      );
    }
  }
}
