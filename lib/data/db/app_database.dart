import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

// Database Constants
const String databaseName = 'vehicle_care_db.sqlite';
const int databaseVersion = 1;

// Table Names
const String tableVehicle = 'vehicles';
const String tableFillUpLog = 'fill_up_logs';
const String tableMaintenanceLog = 'maintenance_logs';
const String tableMaintenanceReminder = 'maintenance_reminders';

class AppDatabase {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await _initDatabase();
    return _database!;
  }

  // Database initialization function
  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, databaseName);

    return await openDatabase(
      path,
      version: databaseVersion,
      onCreate: _onCreate,
    );
  }

  // --- 1. Table Creation (onCreate) ---
  
  // This function runs only when the database is created for the first time.
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      -- 1. Vehicle Table
      CREATE TABLE $tableVehicle (
        vehicleId INTEGER PRIMARY KEY,
        nickname TEXT NOT NULL,
        photoPath TEXT,
        makeModel TEXT,
        licensePlate TEXT,
        initialOdometer REAL NOT NULL,
        avgFe REAL
      );
    ''');
    
    await db.execute('''
      -- 2. FillUpLog Table (Foreign Key: vehicleId)
      CREATE TABLE $tableFillUpLog (
        logId INTEGER PRIMARY KEY,
        vehicleId INTEGER NOT NULL,
        date TEXT NOT NULL,
        distanceAtFilling REAL NOT NULL,
        gasAdded REAL NOT NULL,
        feCalculated REAL,
        -- CONSTRAINT for data integrity (Foreign Key Enforcement)
        FOREIGN KEY (vehicleId) REFERENCES $tableVehicle(vehicleId)
          ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      -- 3. MaintenanceLog Table (Foreign Key: vehicleId)
      CREATE TABLE $tableMaintenanceLog (
        maintenanceId INTEGER PRIMARY KEY,
        vehicleId INTEGER NOT NULL,
        date TEXT NOT NULL,
        serviceType TEXT NOT NULL,
        odometer REAL NOT NULL,
        FOREIGN KEY (vehicleId) REFERENCES $tableVehicle(vehicleId)
          ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      -- 4. MaintenanceReminder Table (Foreign Key: vehicleId)
      CREATE TABLE $tableMaintenanceReminder (
        reminderId INTEGER PRIMARY KEY,
        vehicleId INTEGER NOT NULL,
        serviceType TEXT NOT NULL,
        intervalType TEXT NOT NULL, -- 'Distance' or 'Time'
        intervalValue REAL NOT NULL,
        lastTriggerOdometer REAL NOT NULL,
        lastTriggerDate TEXT NOT NULL,
        FOREIGN KEY (vehicleId) REFERENCES $tableVehicle(vehicleId)
          ON DELETE CASCADE
      );
    ''');
    
    // Enable Foreign Key support immediately after table creation
    await db.execute("PRAGMA foreign_keys = ON;");
  }

  // --- 2. Close Database Connection (Best Practice) ---
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}