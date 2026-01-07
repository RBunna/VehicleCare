import 'package:flutter/material.dart';
import 'package:vehicle_care/data/models/vehicle.dart';
import 'package:vehicle_care/services/managers/reminder_manager.dart';

class VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  final VoidCallback onTap;
  final double currentOdometer; 

  const VehicleCard({
    super.key,
    required this.vehicle,
    required this.onTap,
    required this.currentOdometer, 
  });

  Color _getStatusColor(BuildContext context, MaintenanceStatus status) {
    switch (status) {
      case MaintenanceStatus.critical:
        return Theme.of(context).colorScheme.errorContainer;
      case MaintenanceStatus.warning:
        return Theme.of(context).colorScheme.tertiaryContainer;
      case MaintenanceStatus.ok:
        return Theme.of(context).colorScheme.secondaryContainer;
    }
  }

  Color _getOnStatusColor(BuildContext context, MaintenanceStatus status) {
    switch (status) {
      case MaintenanceStatus.critical:
        return Theme.of(context).colorScheme.onErrorContainer;
      case MaintenanceStatus.warning:
        return Theme.of(context).colorScheme.onTertiaryContainer;
      case MaintenanceStatus.ok:
        return Theme.of(context).colorScheme.onSecondaryContainer;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 380,
        height: 204,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Vehicle Image, Model, and Plate
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: vehicle.photoPath != null && vehicle.photoPath!.isNotEmpty
                      ? Image.asset(
                          vehicle.photoPath!,
                          width: 76,
                          height: 76,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 76,
                          height: 76,
                          color: colorScheme.surfaceContainerHighest,
                          child: Icon(
                            Icons.directions_car,
                            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                            size: 40,
                          ),
                        ),
                ),
                const SizedBox(width: 16),

                // Content (Model, Status, Plate)
                Expanded(
                  child: SizedBox(
                    height: 76,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Model + Status Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Model
                            Flexible(
                              child: Text(
                                vehicle.nickname,
                                style: textTheme.titleLarge!.copyWith(
                                  color: colorScheme.onSurface,
                                  fontWeight: FontWeight.w400,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Status Pill
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(
                                  context,
                                  vehicle.maintenanceStatus,
                                ),
                                borderRadius: BorderRadius.circular(1000),
                              ),
                              child: Text(
                                vehicle.maintenanceStatus.name.toUpperCase(),
                                style: textTheme.bodyLarge!.copyWith(
                                  color: _getOnStatusColor(
                                    context,
                                    vehicle.maintenanceStatus,
                                  ),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Plate
                        Text(
                          vehicle.licensePlate ?? 'No Plate',
                          style: textTheme.bodyMedium!.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            letterSpacing: 0.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // --- Bottom Status Cards (Odometer and Avg FE) ---
            Row(
              children: [
                // Status Card 1: Current Odometer
                Expanded(
                  child: _buildStatusCard(
                    context,
                    title: 'Current Odo',
                    value: '${currentOdometer.toStringAsFixed(0)} km',
                    colorScheme: colorScheme,
                  ),
                ),
                const SizedBox(width: 8),

                // Status Card 2: Avg FE
                Expanded(
                  child: _buildStatusCard(
                    context,
                    title: 'Avg FE',
                    value: (vehicle.avgFe != null)
                        ? '${vehicle.avgFe!.toStringAsFixed(2)} km/L'
                        : 'N/A',
                    colorScheme: colorScheme,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(
    BuildContext context, {
    required String title,
    required String value,
    required ColorScheme colorScheme,
  }) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Title
          Text(
            title,
            style: textTheme.labelSmall!.copyWith(
              color: colorScheme.onTertiaryContainer.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 4),
          // Value
          Text(
            value,
            style: textTheme.titleMedium!.copyWith(
              color: colorScheme.onTertiaryContainer,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}