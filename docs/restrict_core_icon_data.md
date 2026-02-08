# restrict_core_icon_data

Restricts `CoreIconData` and `CoreMaterialIcons` usage to the coreui package icons directory. This rule enforces icon abstraction by requiring developers to use `CoreIcons` constants instead of directly instantiating icon data classes, ensuring consistent icon management across the codebase.

## Bad ❌
```dart
class MyWidget {
  void build() {
    // Direct CoreIconData instantiation
    final svgIcon = CoreIconData.svg('assets/icons/custom.svg');  // LINT
    final materialIcon = CoreIconData.material(Icons.home);  // LINT
    
    // Direct CoreMaterialIcons access
    final arrow = CoreMaterialIcons.arrowRight;  // LINT
  }
  
  // Type annotations are also flagged
  CoreIconData getIcon() => CoreIcons.arrowRight;  // LINT
  void setIcon(CoreIconData icon) {}  // LINT
}
```

## Good ✅
```dart
class MyWidget {
  void build() {
    // Use CoreIcons constants
    final icon1 = CoreIcons.arrowRight;
    final icon2 = CoreIcons.arrowLeft;
    final icon3 = CoreIcons.microsoft;
    
    // Lists of icons
    final icons = [
      CoreIcons.arrowRight,
      CoreIcons.arrowLeft,
    ];
  }
}
```

## What's Detected
- **Direct instantiation**: `CoreIconData.svg()`, `CoreIconData.material()`
- **Static access**: `CoreMaterialIcons.arrowRight`, `CoreMaterialIcons.arrowLeft`
- **Type annotations**: `CoreIconData` used as return type, parameter type, or in generics

## Excluded Files
- Files under `/lib/src/theme/icons/` directory (coreui icon definitions)
