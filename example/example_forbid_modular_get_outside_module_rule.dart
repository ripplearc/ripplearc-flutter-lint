// ignore_for_file: unused_local_variable
import 'package:flutter_modular/flutter_modular.dart';

class Foo {}

// Normal production code
class ServiceClass {
  void doWork() {
    // LINT
    final foo = Modular.get<Foo>();
  }
}

class FakeService {
  void mock() {
    // LINT
    final mockFoo = Modular.get<Foo>();
  }
}

class CoreModule extends Module {
  @override
  void binds(Injector i) {
    i.addFactory<ServiceClass>(() {
      // OK
      final okFoo = Modular.get<Foo>();
      return ServiceClass();
    });
  }
}
