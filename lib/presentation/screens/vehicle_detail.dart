import 'package:flutter/material.dart';
import 'package:vehicle_care/data/models/maintenance_reminder.dart';
import 'package:vehicle_care/data/models/vehicle.dart';
import 'package:vehicle_care/data/models/fill_up_log.dart';
import 'package:vehicle_care/data/models/maintenance_log.dart';
import 'package:vehicle_care/data/repositories/log_repository.dart';
import 'package:vehicle_care/data/repositories/reminder_repository.dart';
import 'package:vehicle_care/presentation/screens/fuel_log_entry.dart';

import 'package:vehicle_care/presentation/screens/maintenance_log_entry_screen.dart';
import 'package:vehicle_care/presentation/screens/maintenance_reminder_setup_screen.dart';
import 'package:vehicle_care/services/managers/reminder_manager.dart';
import 'package:vehicle_care/data/db/app_database.dart';

class VehicleDetailScreen extends StatefulWidget {
  final Vehicle vehicle;
  const VehicleDetailScreen({super.key, required this.vehicle});

  @override
  State<StatefulWidget> createState() => _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends State<VehicleDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final LogRepository _logRepo;
  late final ReminderRepository _reminderRepo;
  late final ReminderManager _reminderManager;

  late Future<void> _dbInitFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _dbInitFuture = _initializeRepositories();

    _tabController.addListener(_handleTabChange);
  }

  void _handleTabChange() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _initializeRepositories() async {
    final dbInstance = await AppDatabase().database;
    _logRepo = LogRepository(dbInstance);
    _reminderRepo = ReminderRepository(dbInstance);
    _reminderManager = ReminderManager(_reminderRepo, _logRepo);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _refreshData() {
    setState(() {});
  }

  void _onFabPressed() async {
    final int tabIndex = _tabController.index;
    bool? needsRefresh = false;

    if (widget.vehicle.vehicleId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error: Vehicle ID is missing.")),
        );
      }
      return;
    }

    if (tabIndex == 0) {
      needsRefresh = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (c) => LogEntryScreen(vehicle: widget.vehicle),
        ),
      );
    } else if (tabIndex == 1) {
      needsRefresh = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (c) => MaintenanceLogEntryScreen(vehicle: widget.vehicle),
        ),
      );
    } else if (tabIndex == 2) {
      needsRefresh = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (c) =>
              MaintenanceReminderSetupScreen(vehicle: widget.vehicle),
        ),
      );
    }

    if (needsRefresh == true) {
      _refreshData();
    }
  }

  IconData _getFabIcon() {
    switch (_tabController.index) {
      case 0:
        return Icons.local_gas_station;
      case 1:
        return Icons.build;
      case 2:
        return Icons.add_alert;
      default:
        return Icons.add;
    }
  }

  String _getFabTooltip() {
    switch (_tabController.index) {
      case 0:
        return 'Add Fuel Log';
      case 1:
        return 'Add Maintenance Log';
      case 2:
        return 'Set New Reminder';
      default:
        return 'Add Entry';
    }
  }

  Widget _buildFuelLogsTab() {
    if (widget.vehicle.vehicleId == null) {
      return const Center(child: Text("Vehicle ID missing. Cannot load logs."));
    }
    return FutureBuilder<List<FillUpLog>>(
      future: _logRepo.getFillUpLogsByVehicle(widget.vehicle.vehicleId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("No fuel logs recorded yet."));
        }

        final logs = snapshot.data!;
        return ListView.builder(
          itemCount: logs.length,
          itemBuilder: (context, index) {
            final log = logs[index];
            return ListTile(
              title: Text("Date: ${log.date}"),
              subtitle: Text(
                "Odo: ${log.distanceAtFilling.toStringAsFixed(0)} | Gas: ${log.gasAdded.toStringAsFixed(2)} liter",
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "FE: ${log.feCalculated?.toStringAsFixed(2) ?? 'N/A'} km/l",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMaintenanceTab() {
    if (widget.vehicle.vehicleId == null) {
      return const Center(
        child: Text("Vehicle ID missing. Cannot load maintenance."),
      );
    }
    return FutureBuilder<List<MaintenanceLog>>(
      future: _logRepo.getMaintenanceLogsByVehicle(widget.vehicle.vehicleId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("No maintenance history recorded."));
        }

        final logs = snapshot.data!;
        return ListView.builder(
          itemCount: logs.length,
          itemBuilder: (context, index) {
            final log = logs[index];
            return ListTile(
              title: Text(log.serviceType),
              subtitle: Text(
                "Completed on ${log.date} at ${log.odometer.toStringAsFixed(0)} km",
              ),
              leading: const Icon(Icons.build_circle),
            );
          },
        );
      },
    );
  }

  Widget _buildRemindersTab() {
    if (widget.vehicle.vehicleId == null) {
      return const Center(
        child: Text("Vehicle ID missing. Cannot load reminders."),
      );
    }
    return FutureBuilder<List<ReminderStatus>>(
      future: _reminderManager.checkAllReminders(widget.vehicle.vehicleId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("No reminders configured. Add one!"));
        }

        final statuses = snapshot.data!;
        return ListView.builder(
          itemCount: statuses.length,
          itemBuilder: (context, index) {
            final status = statuses[index];

            Color statusColor;
            IconData statusIcon;

            if (status.status.toString() == 'MaintenanceStatus.critical') {
              statusColor = Theme.of(context).colorScheme.error;
              statusIcon = Icons.warning;
            } else if (status.status.toString() ==
                'MaintenanceStatus.warning') {
              statusColor = Theme.of(context).colorScheme.tertiary;
              statusIcon = Icons.notifications_active;
            } else {
              statusColor = Theme.of(context).colorScheme.onSurfaceVariant;
              statusIcon = Icons.check_circle;
            }

            String statusMessage =
                status.status.toString() == 'MaintenanceStatus.critical'
                ? "OVERDUE by ${status.value.toStringAsFixed(0)} ${status.unit.name.toUpperCase()}"
                : status.status.toString() == 'MaintenanceStatus.warning'
                ? "Due in ${status.value.toStringAsFixed(0)} ${status.unit.name.toUpperCase()}"
                : "Service OK";

            return ListTile(
              leading: Icon(statusIcon, color: statusColor),
              title: Text(
                status.serviceType,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                statusMessage,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              trailing: ElevatedButton(
                onPressed: status.status.toString() == 'MaintenanceStatus.ok'
                    ? null
                    : () => _logServiceComplete(status.serviceType),
                child: const Text("Service Done"),
              ),
            );
          },
        );
      },
    );
  }

  void _logServiceComplete(String serviceType) async {
    if (widget.vehicle.vehicleId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Cannot log service: Vehicle ID is null."),
          ),
        );
      }
      return;
    }

    final latestLog = await _logRepo.getLastFillUpLog(
      widget.vehicle.vehicleId!,
    );
    final currentOdo =
        latestLog?.distanceAtFilling ?? widget.vehicle.initialOdometer;

    final allReminders = await _reminderRepo.getRemindersByVehicle(
      widget.vehicle.vehicleId!,
    );

    final reminderIterable = allReminders.where(
      (r) => r.serviceType == serviceType,
    );

    final MaintenanceReminder? reminderToUpdate = reminderIterable.isEmpty
        ? null
        : reminderIterable.first;

    if (reminderToUpdate == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Error finding reminder configuration for service: $serviceType",
            ),
          ),
        );
      }
      return;
    }

    await _reminderManager.logServiceComplete(
      reminderToUpdate,
      currentOdo,
      DateTime.now(),
    );

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (widget.vehicle.vehicleId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Error")),
        body: const Center(
          child: Text("Vehicle data is incomplete. Cannot load details."),
        ),
      );
    }

    return FutureBuilder(
      future: _dbInitFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(widget.vehicle.nickname),
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: "Fuel Logs"),
                Tab(text: "Maintenance"),
                Tab(text: "Reminders"),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildFuelLogsTab(),
              _buildMaintenanceTab(),
              _buildRemindersTab(),
            ],
          ),

          floatingActionButton: FloatingActionButton(
            onPressed: _onFabPressed,
            tooltip: _getFabTooltip(),
            child: Icon(_getFabIcon()),
          ),
        );
      },
    );
  }
}
