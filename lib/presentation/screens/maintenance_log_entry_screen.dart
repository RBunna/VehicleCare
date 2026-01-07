import 'package:flutter/material.dart';
import 'package:vehicle_care/data/models/vehicle.dart';
import 'package:vehicle_care/data/models/maintenance_log.dart';
import 'package:vehicle_care/data/repositories/log_repository.dart';
import 'package:vehicle_care/data/db/app_database.dart';

class MaintenanceLogEntryScreen extends StatefulWidget {
  final Vehicle vehicle;
  const MaintenanceLogEntryScreen({super.key, required this.vehicle});

  @override
  State<MaintenanceLogEntryScreen> createState() =>
      _MaintenanceLogEntryScreenState();
}

class _MaintenanceLogEntryScreenState extends State<MaintenanceLogEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _serviceTypeController = TextEditingController();
  final _odometerController = TextEditingController();

  DateTime _date = DateTime.now();
  late LogRepository _logRepo;
  late Future<void> _dbInitFuture;

  @override
  void initState() {
    super.initState();
    _dbInitFuture = _initializeDependencies();
  }

  Future<void> _initializeDependencies() async {
    final dbInstance = await AppDatabase().database;
    _logRepo = LogRepository(dbInstance);
  }

  @override
  void dispose() {
    _serviceTypeController.dispose();
    _odometerController.dispose();

    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _date) {
      setState(() {
        _date = picked;
      });
    }
  }

  void _saveMaintenanceLog() async {
    if (!_formKey.currentState!.validate()) return;

    final odometer = double.parse(_odometerController.text);

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

    final newLog = MaintenanceLog(
      vehicleId: vehicleId,
      date: _date.toIso8601String().substring(0, 10),
      serviceType: _serviceTypeController.text.trim(),
      odometer: odometer,
    );
    await _logRepo.createMaintenanceLog(newLog);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${newLog.serviceType} logged successfully!")),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Log Maintenance")),
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
                ListTile(
                  title: Text(
                    "Date: ${_date.toIso8601String().substring(0, 10)}",
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () => _selectDate(context),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _serviceTypeController,
                  decoration: const InputDecoration(
                    labelText: 'Service Performed *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.isEmpty
                      ? 'Service type is required'
                      : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _odometerController,
                  decoration: const InputDecoration(
                    labelText: 'Odometer at Service (km) *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Odometer is required';
                    final double? odo = double.tryParse(v);
                    if (odo == null) return 'Must be a valid number';

                    if (odo < widget.vehicle.initialOdometer) {
                      return 'Must be greater than initial odometer (${widget.vehicle.initialOdometer} km)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: _saveMaintenanceLog,
                  child: const Text("Save Maintenance Log"),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
