import 'dart:async';

import 'package:riverpod/misc.dart';
import 'package:riverpod/riverpod.dart';

import 'scoped_ref.dart';

/// Runs a function with a [ScopedRef] that is disposed when the function ends.
///
/// The ref is scoped to the surrounding [riverpodScope] call, and will be
/// disposed when the scope ends. Whether this disposes any providers depends on
/// how the providers are used, but scoped providers and auto-disposable
/// providers only using below the scope will be disposed.
Future<T> riverpodScope<T>(
  FutureOr<T> Function(ScopedRef) body, {
  ProviderContainer? parent,
  List<Override> overrides = const [],
  List<ProviderObserver>? observers,
  Duration? Function(int, Object)? retry,
  bool pumpAfterDispose = true,
}) async {
  final container = ProviderContainer(
    parent: parent,
    overrides: overrides,
    observers: observers,
    retry: retry,
  );
  final ref = ScopedRef(container);
  try {
    return await body(ref);
  } finally {
    ref.dispose();
    container.dispose();
    if (pumpAfterDispose) {
      await container.pump();
    }
  }
}
