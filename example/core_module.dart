import 'example_forbid_modular_get_outside_module_rule.dart';

class CoreModule extends Module {
  @override
  void binds(Injector i) {
    i.addFactory<ServiceClass>(() {
      // OK — this file ends in _module.dart
      Modular.get<Foo>();
      return ServiceClass();
    });
  }
}
