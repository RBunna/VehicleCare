import 'package:flutter/material.dart';
import 'package:vehicle_care/data/models/vehicle.dart';

import 'package:vehicle_care/data/models/maintenance_reminder.dart';
import 'package:vehicle_care/data/repositories/reminder_repository.dart';
import 'package:vehicle_care/data/db/app_database.dart';

class MaintenanceReminderSetupScreen extends StatefulWidget {
  final Vehicle vehicle;
  const MaintenanceReminderSetupScreen({super.key, required this.vehicle});

  @override
  State<MaintenanceReminderSetupScreen> createState() =>
      _MaintenanceReminderSetupScreenState();
}

class _MaintenanceReminderSetupScreenState
    extends State<MaintenanceReminderSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _serviceTypeController = TextEditingController();
  final _intervalValueController = TextEditingController();

  IntervalType _selectedIntervalType = IntervalType.distance;
  late ReminderRepository _reminderRepo;
  late Future<void> _dbInitFuture;

  @override
  void initState() {
    super.initState();
    _dbInitFuture = _initializeDependencies();
  }

  Future<void> _initializeDependencies() async {
    final dbInstance = await AppDatabase().database;
    _reminderRepo = ReminderRepository(dbInstance);
  }

  @override
  void dispose() {
    _serviceTypeController.dispose();
    _intervalValueController.dispose();
    super.dispose();
  }

  void _saveReminder() async {
    if (!_formKey.currentState!.validate()) return;

    final intervalValue = double.parse(_intervalValueController.text);
    final vehicleId = widget.vehicle.vehicleId;

    if (vehicleId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error: Vehicle ID not found.")),
        );
      }
      return;
    }

    await _dbInitFuture;

    final newReminder = MaintenanceReminder(
      vehicleId: vehicleId,
      serviceType: _serviceTypeController.text.trim(),

      intervalType: _selectedIntervalType,
      intervalValue: intervalValue,

      lastTriggerOdometer: widget.vehicle.initialOdometer,
      lastTriggerDate: DateTime.now().toIso8601String().substring(0, 10),
    );

    await _reminderRepo.createReminder(newReminder);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${newReminder.serviceType} reminder set!")),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    String getUnitText(IntervalType type) {
      if (type == IntervalType.distance) return 'km';
      if (type == IntervalType.time) return 'months';
      return '';
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Set Up New Reminder")),
      body: FutureBuilder(
        future: _dbInitFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                TextFormField(
                  controller: _serviceTypeController,
                  decoration: const InputDecoration(
                    labelText: 'Service Type (e.g., Oil Change, Tire Rotation)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.isEmpty
                      ? 'Service type is required'
                      : null,
                ),
                const SizedBox(height: 16),

                ListTile(
                  title: const Text("Interval Type"),
                  trailing: DropdownButton<IntervalType>(
                    value: _selectedIntervalType,
                    items: IntervalType.values
                        .map(
                          (type) => DropdownMenuItem(
                            value: type,
                            child: Text(type.name.toUpperCase()),
                          ),
                        )
                        .toList(),
                    onChanged: (IntervalType? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedIntervalType = newValue;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _intervalValueController,
                  decoration: InputDecoration(
                    labelText:
                        'Interval Value (${getUnitText(_selectedIntervalType)})',
                    border: const OutlineInputBorder(),
                    suffixText: getUnitText(_selectedIntervalType),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    final value = double.tryParse(v ?? '');
                    if (value == null || value <= 0) {
                      return 'Must be a positive number';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: _saveReminder,
                  child: const Text("Create Reminder"),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
