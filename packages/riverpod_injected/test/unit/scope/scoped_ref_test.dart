import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod_injected/src/scope/scoped_ref.dart';
import 'package:test/test.dart';

import '../helpers.dart';

part 'scoped_ref_test.g.dart';

@riverpod
int basic(Ref ref) => 42;

@riverpod
Stream<int> stream(Ref ref) =>
    .periodic(const .new(milliseconds: 100), (i) => i);

@Riverpod(retry: _noRetry)
int error(Ref ref) => throw Exception('test');

@Riverpod(keepAlive: true)
DateTime now(Ref ref) => DateTime.now();

Duration? _noRetry(int _, Object _) => null;

void main() {
  group('$ScopedRef', () {
    late ProviderContainer container;
    late ScopedRef sut;

    setUp(() {
      container = ProviderContainer.test();
      sut = ScopedRef(container);
    });

    test('exists reports whether the provider exists', () {
      expect(sut.exists(basicProvider), isFalse);

      container.lock(basicProvider);

      expect(sut.exists(basicProvider), isTrue);
    });

    test('read reads provider without listening', () async {
      expect(sut.read(basicProvider), 42);

      await pumpEventQueue();

      expect(container.exists(basicProvider), isFalse);
    });

    test('listen reads the provider and listens for changes', () async {
      final sub = sut.listen(
        streamProvider,
        expectAsync2((previous, next) {
          switch ((previous, next)) {
            case (const AsyncLoading<int>(), const AsyncData<int>(0)):
              break;
            case (const AsyncData<int>(0), const AsyncData<int>(1)):
              break;
            default:
              fail('Unexpected state change: $previous -> $next');
          }
        }, count: 2),
      );
      addTearDown(sub.close);

      expect(sub.read(), const AsyncLoading<int>());
      await Future<void>.delayed(const Duration(milliseconds: 110));
      expect(sub.read(), const AsyncData<int>(0));
      await Future<void>.delayed(const Duration(milliseconds: 110));
      expect(sub.read(), const AsyncData<int>(1));
    });

    group('stream', () {
      test('streams provider events', () {
        expect(
          sut.stream(streamProvider).take(3),
          emitsInOrder([
            const AsyncData<int>(0),
            const AsyncData<int>(1),
            const AsyncData<int>(2),
          ]),
        );
      });

      test('fires immediately if set', () {
        expect(
          sut.stream(streamProvider, fireImmediately: true).take(3),
          emitsInOrder([
            const AsyncLoading<int>(),
            const AsyncData<int>(0),
            const AsyncData<int>(1),
          ]),
        );
      });

      test('can pause and resume', () async {
        final sub = sut
            .stream(streamProvider)
            .listen(expectAsync1((event) {}, count: 2));
        addTearDown(sub.cancel);

        await Future<void>.delayed(const Duration(milliseconds: 110));

        sub.pause();
        expect(sub.isPaused, isTrue);

        await Future<void>.delayed(const Duration(milliseconds: 330));

        sub.resume();
        expect(sub.isPaused, isFalse);

        await Future<void>.delayed(const Duration(milliseconds: 110));
      });

      test('forwards errors', () {
        expect(
          sut.stream(errorProvider, fireImmediately: true).take(1),
          emitsError(
            isA<Exception>().having(
              (m) => m.toString(),
              'toString()',
              'Exception: test',
            ),
          ),
        );
      });
    });

    test('watch reads provider and keeps it alive until disposed', () async {
      expect(sut.watch(basicProvider), 42);

      await pumpEventQueue();

      expect(container.exists(basicProvider), isTrue);

      sut.dispose();
      await pumpEventQueue();

      expect(container.exists(basicProvider), isFalse);
    });

    test('refresh refreshes the provider', () async {
      final initial = sut.read(nowProvider);

      await Future<void>.delayed(const .new(milliseconds: 1));
      await pumpEventQueue();

      expect(sut.read(nowProvider), initial);
      expect(sut.refresh(nowProvider), isNot(initial));
    });

    test('invalidate invalidates the provider', () async {
      final initial = sut.read(nowProvider);

      await Future<void>.delayed(const .new(milliseconds: 1));
      await pumpEventQueue();

      expect(sut.read(nowProvider), initial);
      sut.invalidate(nowProvider);
      expect(sut.read(nowProvider), isNot(initial));
    });
  });
}
