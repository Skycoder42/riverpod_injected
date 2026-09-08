/// @docImport 'riverpod_scope.dart';
library;

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:riverpod/misc.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

/// A [Ref]-like object that is scoped to a [riverpodScope] call.
///
/// Similar to [Ref], it allows [read]ing, [listen]ing, and [watch]ing
/// providers. It also provides [keep], [refresh], and [invalidate] methods,
/// with [keep] being a special variant of [read] that keeps auto-disposable
/// providers alive until the surrounding [riverpodScope] call has finished.
/// This is useful for cases where an async provider does some work without
/// anything else specifically watching it.
class ScopedRef(final ProviderContainer container) {
  final _keepAliveSubs = <ProviderListenable<dynamic>, ProviderSubscription>{};

  /// @nodoc
  @internal
  this;

  /// Determines whether a [provider] is initialized or not.
  ///
  /// See [Ref.exists] for more details.
  bool exists(ProviderBase<Object?> provider) => container.exists(provider);

  /// Reads a [provider] without listening to it and returns the currently
  /// exposed value.
  ///
  /// **Important:** If the provider is an auto-disposable provider, it will be
  /// disposed as soon as the application returns to the event loop. For async
  /// providers this can mean they get disposed before they finish their work.
  /// Using `ref.read(provider.future)` will **not** prevent the provider from
  /// being disposed, and will throw an error if the provider is disposed before
  /// it finishes. If you want to keep an auto-disposable provider alive until
  /// the surrounding scope callback has finished, use [keep] instead.
  ///
  /// See [Ref.read] for more details.
  T read<T>(ProviderListenable<T> provider) => container.read(provider);

  /// Listen to a [provider] and call [listener] whenever its value changes.
  ///
  /// See [Ref.listen] for more details.
  ProviderSubscription<T> listen<T>(
    ProviderListenable<T> provider,
    void Function(T? previous, T next) listener, {
    bool fireImmediately = false,
    bool weak = false,
    void Function(Object, StackTrace)? onError,
  }) => container.listen(
    provider,
    listener,
    fireImmediately: fireImmediately,
    weak: weak,
    onError: onError,
  );

  /// Listens to a [provider] and returns a stream of its state.
  ///
  /// The stream will emit the current state of the [provider] (if
  /// [fireImmediately] is true) and any subsequent updates, as well as provider
  /// errors that might occur. Pausing the stream will pause the provider
  /// subscription, which may notify the provider if no other listeners are
  /// active. You can also use [weak] to make the subscription weak.
  ///
  /// See [Ref.watch] for more details.
  Stream<T> watch<T>(
    ProviderListenable<T> provider, {
    bool fireImmediately = false,
    bool weak = false,
  }) {
    late ProviderSubscription<T> providerSub;
    late StreamController<T> controller;
    controller = StreamController<T>(
      onListen: () {
        providerSub = container.listen(
          provider,
          (_, next) => controller.add(next),
          fireImmediately: fireImmediately,
          weak: weak,
          onError: (error, stackTrace) =>
              controller.addError(error, stackTrace),
        );
      },
      onCancel: () async {
        providerSub.close();
        await controller.close();
      },
      onPause: () => providerSub.pause(),
      onResume: () => providerSub.resume(),
    );
    return controller.stream;
  }

  /// Reads a provider without listening to it.
  ///
  /// Works just like [Ref.read], but with one minor difference: If the provider
  /// is a auto disposable provider, it will not be disposed until the
  /// [ScopedRef] itself is disposed. This means it will stay alive until the
  /// surrounding scope callback has finished. Internally, [Ref.listen] is used
  /// to achieve this.
  ///
  /// See [Ref.read] and [Ref.watch] for more details.
  T keep<T>(ProviderListenable<T> provider) {
    final subscription = _keepAliveSubs.putIfAbsent(
      provider,
      () => container.listen(provider, (_, _) {}),
    ) as ProviderSubscription<T>;
    return subscription.read();
  }

  /// Forces a [provider] to re-evaluate its state immediately, and return the
  /// created value.
  ///
  /// See [Ref.refresh] for more details.
  @useResult
  State refresh<State>(Refreshable<State> provider) =>
      container.refresh(provider);

  /// Invalidates the state of the [provider], destroying the state immediately
  /// and causing the [provider] to rebuild at some point in the future.
  ///
  /// See [Ref.invalidate] for more details.
  void invalidate(ProviderOrFamily provider) => container.invalidate(provider);

  /// @nodoc
  @internal
  void dispose() {
    for (final subscription in _keepAliveSubs.values) {
      subscription.close();
    }
  }
}
