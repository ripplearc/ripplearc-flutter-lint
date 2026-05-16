// ignore_for_file: unused_local_variable

class Modular {
  static T get<T>() => throw UnimplementedError();
}

class Module {
  void binds(Injector i) {}
}

class Injector {
  void addFactory<T>(T Function() f) {}
}

class Foo {}

class AppRouter {}

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

class AnalyticsConsumer {
  void track() {
    // OK — AppRouter declared in allow_list in analysis_options.yaml
    final router = Modular.get<AppRouter>();
  }
}

