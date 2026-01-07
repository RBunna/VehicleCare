import 'package:flutter/material.dart';
import 'package:vehicle_care/data/models/fill_up_log.dart';
import 'package:vehicle_care/data/models/vehicle.dart';
import 'package:vehicle_care/data/repositories/log_repository.dart';
import 'package:vehicle_care/data/repositories/vehicle_repository.dart';
import 'package:vehicle_care/services/calculators/fe_calculator.dart';
import 'package:vehicle_care/data/db/app_database.dart';

class LogEntryScreen extends StatefulWidget {
  final Vehicle vehicle;
  const LogEntryScreen({super.key, required this.vehicle});

  @override
  State<LogEntryScreen> createState() => _LogEntryScreenState();
}

class _LogEntryScreenState extends State<LogEntryScreen> {
  final _odometerController = TextEditingController();
  final _gasAddedController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  DateTime _date = DateTime.now();

  late LogRepository _logRepo;
  late VehicleRepository _vehicleRepo;
  late FECalculator _feCalculator;
  late Future<void> _dbInitFuture;

  double? _distanceTraveled;
  double? _estimatedFe;

  bool _canSave = false;

  @override
  void initState() {
    super.initState();
    _dbInitFuture = _initializeDependencies();

    _odometerController.addListener(_updatePreview);
    _gasAddedController.addListener(_updatePreview);
  }

  Future<void> _initializeDependencies() async {
    final dbInstance = await AppDatabase().database;
    _logRepo = LogRepository(dbInstance);
    _vehicleRepo = VehicleRepository(dbInstance);
    _feCalculator = FECalculator(_logRepo, _vehicleRepo);
  }

  @override
  void dispose() {
    _odometerController.removeListener(_updatePreview);
    _gasAddedController.removeListener(_updatePreview);
    _odometerController.dispose();
    _gasAddedController.dispose();
    super.dispose();
  }

  void _updatePreview() async {
    final double? currentOdometer = double.tryParse(_odometerController.text);
    final double? currentGasAdded = double.tryParse(_gasAddedController.text);

    final int? vehicleId = widget.vehicle.vehicleId;

    final bool inputsAreValid =
        currentOdometer != null &&
        currentGasAdded != null &&
        currentGasAdded > 0 &&
        vehicleId != null;

    if (mounted && _canSave != inputsAreValid) {
      setState(() {
        _canSave = inputsAreValid;
      });
    }

    if (inputsAreValid) {
      await _dbInitFuture;

      final lastFillLog = await _logRepo.getLastFillUpLog(vehicleId);

      if (lastFillLog != null) {
        final distance = currentOdometer - lastFillLog.distanceAtFilling;

        if (distance > 0) {
          final fe = distance / currentGasAdded;

          if (mounted) {
            setState(() {
              _distanceTraveled = distance;
              _estimatedFe = fe;
            });
          }
          return;
        }
      }
    }

    if (mounted) {
      setState(() {
        _distanceTraveled = null;
        _estimatedFe = null;
      });
    }
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

  void _saveLogAndCalculate() async {
    final formState = _formKey.currentState;

    if (formState == null || !formState.validate()) {
      setState(() {});
      return;
    }

    final currentOdometer = double.parse(_odometerController.text);
    final currentGasAdded = double.parse(_gasAddedController.text);
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

    final newLog = FillUpLog(
      vehicleId: vehicleId,
      date: _date.toIso8601String().substring(0, 10),
      distanceAtFilling: currentOdometer,
      gasAdded: currentGasAdded,

      feCalculated: _estimatedFe,
    );
    await _logRepo.createFillUpLog(newLog);

    if (_estimatedFe != null) {
      final varianceResult = await _feCalculator.calculateAndSaveVariance(
        vehicleId,
      );

      if (mounted && varianceResult.isSignificantAlert) {
        String message;

        if (varianceResult.variancePercent > 0) {
          message =
              "FE is ${varianceResult.variancePercent.toStringAsFixed(1)}% ABOVE average! Good driving!";
        } else {
          message =
              "FE is ${varianceResult.variancePercent.abs().toStringAsFixed(1)}% BELOW average. Check fuel or driving habits.";
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: varianceResult.variancePercent > 0
                ? const Color(0xFF388E3C)
                : Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 3),
          ),
        );

        await Future.delayed(const Duration(seconds: 3));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("First fuel log saved successfully!")),
        );
        await Future.delayed(const Duration(seconds: 1));
      }
    }

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Log Fill-Up")),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            ListTile(
              title: Text("Date: ${_date.toIso8601String().substring(0, 10)}"),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _selectDate(context),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _odometerController,
              decoration: const InputDecoration(
                labelText: 'Odometer Reading (km) *',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Odometer is required';
                final double? odo = double.tryParse(v);
                if (odo == null) return 'Must be a valid number';
                if (odo <= widget.vehicle.initialOdometer) {
                  return 'Must be greater than initial odometer (${widget.vehicle.initialOdometer} km)';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _gasAddedController,
              decoration: const InputDecoration(
                labelText: 'Fuel Added (litres) *',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Fuel added is required';
                final double? fuel = double.tryParse(v);
                if (fuel == null) return 'Must be a valid number';
                if (fuel <= 0) return 'Must be greater than zero';
                return null;
              },
            ),
            const SizedBox(height: 24),

            if (_estimatedFe != null)
              Card(
                color: Theme.of(context).colorScheme.secondaryContainer,
                margin: const EdgeInsets.only(bottom: 24),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    "PREVIEW:\n"
                    "Distance Traveled: ${(_distanceTraveled as double).toStringAsFixed(0)} km\n"
                    "Est. FE: ${(_estimatedFe as double).toStringAsFixed(2)} km/l",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),

            ElevatedButton(
              onPressed: _canSave ? _saveLogAndCalculate : null,
              child: const Text("Save Log & Calculate"),
            ),
          ],
        ),
      ),
    );
  }
}
