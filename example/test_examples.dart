import 'package:mockito/mockito.dart';

abstract class ApiService {
  Future<String> fetch();
}

// This should trigger the lint warning
class MockApiService extends Mock implements ApiService {}

// This should NOT trigger the lint warning
class FakeApiService extends Fake implements ApiService {
  @override
  Future<String> fetch() async => 'fake data';
} 