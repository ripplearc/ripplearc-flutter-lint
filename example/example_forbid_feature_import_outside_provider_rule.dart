// ignore_for_file: unused_import, uri_does_not_exist

// LINT: deep import into the estimation feature, bypassing its provider file
import 'package:project/features/estimation/domain/entities/estimate.dart';

// LINT: deep import into the estimation feature via export
export 'package:project/features/estimation/presentation/pages/estimation_page.dart';

// LINT: relative deep import into the estimation feature
import '../features/estimation/domain/entities/estimate.dart';

// OK: the estimation feature's own provider file
import 'package:project/features/estimation/estimation_feature_module.dart';

// OK: external packages are never in scope
import 'package:flutter/material.dart';

void main() {
  const enabledFeatures = <EstimationFeatureModule>[EstimationFeatureModule()];
  print(enabledFeatures);
}
