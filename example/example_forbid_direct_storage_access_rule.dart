// ignore_for_file: unused_import, uri_does_not_exist, depend_on_referenced_packages

// LINT: direct use of shared_preferences outside the storage library
import 'package:shared_preferences/shared_preferences.dart';

// LINT: direct use of path_provider outside the storage library
import 'package:path_provider/path_provider.dart';

// LINT: re-exporting flutter_secure_storage is direct use too
export 'package:flutter_secure_storage/flutter_secure_storage.dart';

// OK: other packages are not in scope
import 'package:path/path.dart' as p;

// OK: the storage library is the one place that may use the packages
import 'package:project/libraries/storage/interfaces/storage_service.dart';
