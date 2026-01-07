// lib/data/db/database_factory_initializer.dart

import 'package:flutter/foundation.dart';
import 'package:vehicle_care/data/db/database_factory_initializer_non_web.dart';
import 'package:vehicle_care/data/db/database_factory_initializer_web.dart';

// This function will be defined in the platform-specific files
// It will be empty for Android/iOS, or contain FFI setup for Web/Desktop.
void initializeDatabaseFactory() {
  if (kIsWeb) {
    // If running on web, call the web-specific setup function
    initializeDatabaseFactoryWeb();
  } else if (defaultTargetPlatform != TargetPlatform.android &&
      defaultTargetPlatform != TargetPlatform.iOS) {
    // If Desktop (Windows, Linux, macOS, or testing environment)
    initializeDatabaseFactoryNonWeb();
  }
}
