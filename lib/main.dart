import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:vehicle_care/presentation/screens/home.dart'; 
import 'package:vehicle_care/theme.dart';
import 'package:vehicle_care/data/db/app_database.dart'; 
import 'package:vehicle_care/data/db/database_factory_initializer.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  initializeDatabaseFactory(); 
  runApp(const VehicleCareApp());
}

class VehicleCareApp extends StatelessWidget {
  const VehicleCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VehicleCare Offline Tracker',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      // themeMode: ThemeMode.dark,
      
      home: FutureBuilder<Database>(
        future: AppDatabase().database,
        builder: (context, snapshot) {
          // Check if the Future is complete and contains the Database object
          if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
            final Database db = snapshot.data as Database;
            return HomeScreen(db); 
          }
          
          // Handle initialization error
          if (snapshot.hasError) {
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 10),
                    const Text("FATAL ERROR: Could not initialize database.", style: TextStyle(fontSize: 18)),
                    const SizedBox(height: 5),
                    Text(
                      // snapshot.error is nullable, use null-aware operator if desired, 
                      // but here it's caught inside hasError, so .toString() is common practice.
                      "Details: ${snapshot.error.toString()}",
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    )
                  ],
                ),
              ),
            );
          }
          
          // Show loading screen while connecting
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        },
      ),
    );
  }
}