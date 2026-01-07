import 'package:vehicle_care/data/repositories/log_repository.dart';
import 'package:vehicle_care/data/repositories/vehicle_repository.dart';

class FE_VarianceResult {
  final double variancePercent; // % difference from Avg FE
  final bool isSignificantAlert; // True if variance > 10% (T=10)
  final bool isNegative; // True if FE is worse than average

  FE_VarianceResult({
    required this.variancePercent,
    required this.isSignificantAlert,
    required this.isNegative,
  });
}

enum FeStatus { green, red, ok }

class FECalculator {
  final LogRepository logRepo;
  final VehicleRepository vehicleRepo;

  FECalculator(this.logRepo, this.vehicleRepo);

  // --- Main Execution Method ---
  Future<FE_VarianceResult> calculateAndSaveVariance(int vehicleId) async {
    final lastFillLog = await logRepo.getLastFillUpLog(vehicleId);

    // FIX 1: Guard Clause for first or missing log entry.
    // Variance cannot be calculated with only one log.
    if (lastFillLog == null) {
      return FE_VarianceResult(
        variancePercent: 0.0,
        isSignificantAlert: false,
        isNegative: false,
      );
    }

    // Step 1: Calculate Latest Fill-Up FE (FE_Latest)
    final latestFE = await _calculateLatestFE(
      vehicleId,
      // Now safe to access fields as lastFillLog is non-null
      lastFillLog.distanceAtFilling, 
      lastFillLog.gasAdded,
    );

    // Step 2: Calculate and Update Historical Average FE (Avg FE)
    final avgFE = await _calculateAndUpdateAvgFE(
      vehicleId,
      lastFillLog.distanceAtFilling,
    );

    // Step 3: Calculate Variance Percentage and Decision Logic
    // Guard against avgFE being zero (e.g., if total distance is zero)
    if (avgFE == 0.0) {
        return FE_VarianceResult(
            variancePercent: 0.0,
            isSignificantAlert: false,
            isNegative: false,
        );
    }
    
    final variancePercent = ((latestFE - avgFE) / avgFE) * 100;

    // Decision Logic (Threshold T=10%)
    const double threshold = 10.0;
    final isSignificant = variancePercent.abs() > threshold;
    final isNegative = variancePercent < 0;

    return FE_VarianceResult(
      variancePercent: variancePercent,
      isSignificantAlert: isSignificant,
      isNegative: isNegative,
    );
  }

  // --- Helper 1: Calculates FE_Latest ---
  Future<double> _calculateLatestFE(
    int vehicleId,
    double currentOdo,
    double gasAdded,
  ) async {
    final prevLog = await logRepo.getLastFillUpLog(vehicleId); // Assuming logRepo has a method to skip the absolute latest log

    // Guard Clause: If this is the very first log (or only one log), return zero.
    if (prevLog == null) return 0.0;

    final distanceTraveled = currentOdo - prevLog.distanceAtFilling;
    
    // Guard against division by zero
    if (gasAdded == 0) return 0.0;
    
    return distanceTraveled / gasAdded;
  }

  // --- Helper 2: Calculates and Persists Avg FE ---
  Future<double> _calculateAndUpdateAvgFE(
    int vehicleId,
    double currentOdo,
  ) async {
    // Fetch initial odometer and all existing logs to recalculate total consumption
    final vehicle = await vehicleRepo.getVehicleById(vehicleId);
    final allLogs = await logRepo.getFillUpLogsByVehicle(vehicleId);

    // Guard Clause: Ensure necessary data exists
    if (vehicle == null || allLogs.isEmpty) return 0.0;

    // Calculate Total Distance Traveled
    final totalDistance = currentOdo - vehicle.initialOdometer;

    // Calculate Total Gas Added
    final totalGas = allLogs.fold(0.0, (sum, log) => sum + log.gasAdded);

    // Guard against totalDistance or totalGas being non-positive
    if (totalGas <= 0.0 || totalDistance <= 0.0) return 0.0;

    final newAvgFE = totalDistance / totalGas;

    // Update the Vehicle table with the new cached Avg FE
    await vehicleRepo.updateVehicleAvgFE(vehicleId, newAvgFE);

    return newAvgFE;
  }
}