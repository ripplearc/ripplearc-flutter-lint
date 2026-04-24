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

class StatelessWidget {}

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

class CheckoutPage extends StatelessWidget {
  void openCheckout() {
    // OK
    final router = Modular.get<AppRouter>();
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
