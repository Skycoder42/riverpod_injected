/// @docImport 'riverpod_command_runner.dart';
library;

import 'package:args/command_runner.dart';
import 'package:meta/meta.dart';

import '../scope/scoped_ref.dart';

/// A mixin that provides access to a [ScopedRef] for commands.
///
/// To use it, mix it in your [Command] implementation and make sure to use
/// the [RiverpodCommandRunner] instead of the default [CommandRunner].
mixin RiverpodCommand<T> on Command<T> {
  late ScopedRef _ref;

  /// The [ScopedRef] associated with this command.
  ScopedRef get ref => _ref;

  @internal
  set ref(ScopedRef value) {
    _ref = value;
  }
}
