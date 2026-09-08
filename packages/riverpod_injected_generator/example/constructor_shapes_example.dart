// Field formals, super parameters, optional and defaulted parameters, and the
// Ref itself.

import 'package:riverpod_injected/riverpod_injected.dart';

part 'constructor_shapes_example.di.g.dart';
part 'constructor_shapes_example.g.dart';

@riverDi
class const Engine();

@riverDi
class const Wheels();

/// Field formals are ordinary positional parameters as far as injection goes.
@riverDi
class Car(final Engine engine, final Wheels wheels);

class Vehicle(final Engine engine);

/// A `super.` parameter is forwarded like any other positional parameter.
@riverDi
class Truck(final Wheels wheels, super.engine) extends Vehicle;

/// An optional positional parameter is injected while it has no default of its
/// own; [axles] keeps its default and is left out of the generated call.
@riverDi
class Trailer(final Wheels wheels, [final Engine? engine, final int axles = 2]);

/// The same rule for named parameters: [capacity] keeps its default, while
/// [spare] is optional but undefaulted and so still injected.
@riverDi
class Garage({
  required final Engine engine,
  final Wheels? spare,
  final int capacity = 10,
});

/// A defaulted parameter opts back in by naming its provider explicitly.
@riverDi
class Depot({
  final Wheels wheels = const Wheels(),
  @From(Engine) final Engine? engine,
});

/// A [Ref] parameter is handed the provider's own ref, so a service can manage
/// its own lifecycle.
@riverDi
class Workshop(Ref ref, final Engine engine) {
  var _disposed = false;

  bool get disposed => _disposed;

  this {
    ref.onDispose(() => _disposed = true);
  }
}
