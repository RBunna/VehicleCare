import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:vehicle_care/data/models/vehicle.dart';
import 'package:vehicle_care/data/repositories/vehicle_repository.dart';
import 'package:vehicle_care/data/repositories/log_repository.dart';
import 'package:vehicle_care/presentation/common/vehicle_card.dart';
import 'package:vehicle_care/presentation/screens/add_vehicle.dart';
import 'package:vehicle_care/presentation/screens/vehicle_detail.dart';

class HomeScreen extends StatefulWidget {
  final Database db;
  const HomeScreen(this.db, {super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class VehicleMetrics {
  final Vehicle vehicle;
  final double latestOdometer;

  VehicleMetrics({required this.vehicle, required this.latestOdometer});
}

class _HomeScreenState extends State<HomeScreen> {
  List<VehicleMetrics> _vehicleMetrics = [];
  late VehicleRepository _vehicleRepo;
  late LogRepository _logRepo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _vehicleRepo = VehicleRepository(widget.db);
    _logRepo = LogRepository(widget.db);
    _loadVehicles();
  }

  void _loadVehicles() async {
    final fetchedVehicles = await _vehicleRepo.getAllVehiclesWithMetrics();

    List<VehicleMetrics> metricsList = [];

    for (var vehicle in fetchedVehicles) {
      if (vehicle.vehicleId != null) {
        final latestLog = await _logRepo.getLastFillUpLog(vehicle.vehicleId!);

        final currentOdo =
            latestLog?.distanceAtFilling ?? vehicle.initialOdometer;

        metricsList.add(
          VehicleMetrics(vehicle: vehicle, latestOdometer: currentOdo),
        );
      }
    }

    if (mounted) {
      setState(() {
        _vehicleMetrics = metricsList;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "VehicleCare",
          style:
              Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ) ??
              const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : (_vehicleMetrics.isEmpty
                ? _buildEmptyState()
                : _buildVehicleList()),

      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (c) => AddVehicleScreen()),
          );
          _loadVehicles();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildVehicleList() {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: _vehicleMetrics.length,
      itemBuilder: (context, index) {
        final metrics = _vehicleMetrics[index];

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: VehicleCard(
            vehicle: metrics.vehicle,
            currentOdometer: metrics.latestOdometer,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (c) => VehicleDetailScreen(vehicle: metrics.vehicle),
                ),
              );
              _loadVehicles();
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.drive_eta, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text("No vehicles added yet.", style: TextStyle(fontSize: 20)),
          SizedBox(height: 8),
          Text(
            "Tap the '+' to start tracking fuel logs and maintenance.",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
