// ignore: invalid_use_of_internal_member for test validation
import 'package:riverpod/src/framework.dart' show ProviderContainerTest;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod_injected/src/scope/riverpod_scope.dart';
import 'package:test/test.dart';

part 'riverpod_scope_test.g.dart';

@Riverpod(dependencies: [], keepAlive: true)
int scoped(Ref ref) => throw UnimplementedError();

@riverpod
int kept(Ref ref) => 11;

void main() {
  group('$riverpodScope', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer.test();
    });

    test('disposes the container after the body is executed', () async {
      late ProviderContainer inner;

      await riverpodScope(parent: container, (ref) {
        inner = ref.container;
        expect(inner, isNotNull);
        expect(inner, isNot(container));
      });

      expect(inner.disposed, isTrue);
      expect(container.disposed, isFalse);
    });

    test('disposes kept providers', () async {
      expect(container.exists(keptProvider), isFalse);

      await riverpodScope(parent: container, (ref) {
        expect(ref.watch(keptProvider), 11);
        expect(container.exists(keptProvider), isTrue);
      });

      expect(container.exists(keptProvider), isFalse);
    });

    test('disposes scoped providers', () async {
      expect(container.exists(scopedProvider), isFalse);

      await riverpodScope(
        parent: container,
        overrides: [scopedProvider.overrideWithValue(42)],
        (ref) {
          expect(ref.read(scopedProvider), 42);
        },
      );

      expect(container.exists(scopedProvider), isFalse);
    });
  });
}
