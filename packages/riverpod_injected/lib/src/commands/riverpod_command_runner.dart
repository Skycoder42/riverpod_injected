import 'dart:async';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:meta/meta.dart';
import 'package:riverpod/misc.dart';
import 'package:riverpod/riverpod.dart';

import '../scope/riverpod_scope.dart';
import '../scope/scoped_ref.dart';
import 'riverpod_command.dart';

/// A helper class to configure the scoped [ProviderContainer].
class const ContainerConfiguration({
  final List<Override> overrides = const [],
  final List<ProviderObserver>? observers,
  final Duration? Function(int, Object)? retry,
}) {
  /// Default constructor
  this;
}

/// A custom [CommandRunner] that integrates with Riverpod.
///
/// It ensures that all commands have access to a [ScopedRef] and allows for
/// the configuration of scoped provider overrides. Commands can access the
/// [ScopedRef] by mixing in [RiverpodCommand] and using the
/// [RiverpodCommand.ref] property.
abstract base class RiverpodCommandRunner<TReturn>(
  super.executableName,
  super.description, {
  final ProviderContainer? _parent,
  super.usageLineLength,
  super.suggestionDistanceLimit,
}) extends CommandRunner<TReturn> {
  /// Default constructor.
  ///
  /// See [CommandRunner.new] for more details.
  this;

  /// Allows you to configure custom overrides, observers and the retry logic
  /// for the internally used [ProviderContainer]. It will be invoked with the
  /// [topLevelResults] of the command line arguments, right before executing
  /// the actual command.
  @protected
  ContainerConfiguration configureContainer(ArgResults topLevelResults) =>
      // ignore: deprecated_member_use_from_same_package for backwards compatibility
      .new(overrides: configureOverrides(topLevelResults));

  /// @nodoc
  @protected
  @Deprecated('Use configureContainer instead')
  List<Override> configureOverrides(ArgResults topLevelResults) => const [];

  /// Is invoked by the runner to actually execute a command.
  ///
  /// Serves as a replacement for [runCommand] (which must not be overridden by
  /// subclasses). It internally invokes [runCommand], but allows you to add
  /// logic right before and after a command is run, with access to the scoped
  /// [ref] as well as the [topLevelResults] of the command line arguments.
  @mustCallSuper
  Future<TReturn?> runProviderCommand(
    ArgResults topLevelResults,
    ScopedRef ref,
  ) => super.runCommand(topLevelResults);

  @override
  @nonVirtual
  Future<TReturn?> runCommand(ArgResults topLevelResults) async {
    final ContainerConfiguration(:overrides, :observers, :retry) =
        configureContainer(topLevelResults);

    return await riverpodScope(
      parent: _parent,
      overrides: overrides,
      observers: observers,
      retry: retry,
      (ref) async {
        final commandInstances = _expandRecursive(commands)
            .whereType<RiverpodCommand<dynamic>>()
            .toSet();
        for (final command in commandInstances) {
          command.ref = ref;
        }

        return await runProviderCommand(topLevelResults, ref);
      },
    );
  }

  Iterable<Command<dynamic>> _expandRecursive(
    Map<String, Command<dynamic>> commands,
  ) sync* {
    for (final command in commands.values) {
      yield command;
      for (final subcommand in command.subcommands.values) {
        yield* _expandRecursive({subcommand.name: subcommand});
      }
    }
  }
}
