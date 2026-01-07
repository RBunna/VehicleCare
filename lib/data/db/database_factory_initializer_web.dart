// lib/data/db/database_factory_initializer_web.dart

import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

// This overrides the function stub in the main initializer file
void initializeDatabaseFactoryWeb() {
  // Use the web factory when running on the web
  databaseFactory = databaseFactoryFfiWeb;
}