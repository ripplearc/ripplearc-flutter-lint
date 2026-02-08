# prevent_feature_module_dependencies

Enforces feature module independence by preventing feature modules from depending on other feature modules. This rule ensures that each feature can be developed, tested, and deployed in isolation, reducing coupling and improving modularity.

## Bad ❌
```dart
// lib/features/estimation/presentation/pages/estimation_page.dart
import 'package:project/features/estimation/data/models/estimation.dart'; // LINT: Feature importing another feature
import 'package:project/features/estimation/domain/entities/estimation.dart'; // LINT: Feature importing another feature

class DashboardPage {
  void displayDate(Dashboard dashboard) {
    print('Date: ${dashboard.date}');
  }

  void display(ResentAction recentAction) {
    print('Recent Action: ${recentAction.last}');
  }
}
```

## Good ✅
```dart
// lib/features/dashboard/presentation/pages/dashboard_page.dart

// Good: Imports from the same feature
import 'package:project/features/dashboard/domain/entities/order.dart';
import 'package:project/features/dashboard/data/models/dashboard_model.dart';
import '../presentation/widgets/dashboard_form.dart'; // Relative imports are OK

// Good: External packages
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CheckoutPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: Column(
        children: [
          AppButton(label: 'Continue', onPressed: () {}),
          const DashboardForm(),
        ],
      ),
    );
  }
}
```

## Allowed Patterns
- **Same feature imports**: Features can import from their own feature (`package:project/features/{same_feature}/...`)
- **Relative imports**: Features can use relative imports within the same feature
- **External packages**: All features can import from Flutter, Dart SDK, and pub.dev packages
- **Non-feature files**: Files outside the features directory (like `main.dart`, `app.dart`) can import features for initialization

## Feature Structure
```
lib/
├── features/
│   ├── auth/              # Independent feature
│   ├── dashboard/         # Independent feature
│   ├── estimation/        # Independent feature
│   └── project/           # Independent feature
├── libraries/                  
```
