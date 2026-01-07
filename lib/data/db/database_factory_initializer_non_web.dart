// lib/data/db/database_factory_initializer_non_web.dart

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// This overrides the function stub in the main initializer file
void initializeDatabaseFactoryNonWeb() {
  // Use the standard FFI factory for non-web environments (Desktop/Test)
  databaseFactory = databaseFactoryFfi;
}