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

class GlobalCrashReporter {}

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

class CrashReportingBootstrapper {
  void init() {
    // OK — GlobalCrashReporter declared in allow_list in analysis_options.yaml
    final reporter = Modular.get<GlobalCrashReporter>();
  }
}

