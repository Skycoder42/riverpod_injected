import 'package:args/command_runner.dart';
import 'package:args/src/arg_results.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod_injected/src/commands/riverpod_command.dart';
import 'package:riverpod_injected/src/commands/riverpod_command_runner.dart';
import 'package:test/test.dart';

import '../helpers.dart';
@GenerateNiceMocks([MockSpec<Command<int?>>()])
import 'riverpod_command_runner_test.mocks.dart';

part 'riverpod_command_runner_test.g.dart';

@riverpod
int simple(Ref ref) => 42;

@Riverpod(dependencies: [])
int scoped(Ref ref) => 0;

class TestCommand(final MockCommand mock)
    extends Command<int?>
    with RiverpodCommand {
  @override
  String get name => mock.name;

  @override
  String get description => mock.description;

  @override
  FutureOr<int?>? run() => mock.run();
}

class TestCommandGroup(Iterable<Command<int?>> subCommands)
    extends Command<int?> {
  this {
    subCommands.forEach(addSubcommand);
  }

  @override
  String get name => 'group';

  @override
  String get description => 'group description';
}

final class TestRunner(
  TestCommand command,
  TestCommand subCommand, {
  super.parent,
}) extends RiverpodCommandRunner<int?> {
  this : super('test', 'test description') {
    addCommand(command);
    addCommand(TestCommandGroup([subCommand]));
  }

  @override
  ContainerConfiguration configureContainer(ArgResults topLevelResults) =>
      .new(overrides: [scopedProvider.overrideWithValue(11)]);
}

void main() {
  group('$RiverpodCommandRunner', () {
    late ProviderContainer container;
    late TestCommand command;
    late TestCommand subCommand;
    late TestRunner sut;

    setUp(() {
      container = ProviderContainer.test();
      command = TestCommand(MockCommand());
      subCommand = TestCommand(MockCommand());

      when(command.mock.name).thenReturn('test');
      when(subCommand.mock.name).thenReturn('sub');

      sut = TestRunner(command, subCommand, parent: container);
    });

    test('is able to run a command', () async {
      final result = await sut.run(['test']);
      expect(result, isNull);
    });

    test('scopes provider to the command', () async {
      when(command.mock.run()).thenAnswer((i) {
        expect(command.ref, isNotNull);
        expect(command.ref.watch(simpleProvider), 42);
        expect(container.exists(simpleProvider), isTrue);
        return 42;
      });

      expect(container.exists(simpleProvider), isFalse);

      final result = await sut.run(['test']);
      expect(result, 42);

      expect(container.exists(simpleProvider), isFalse);

      verify(command.mock.run()).called(1);
    });

    test('scopes provider to sub commands', () async {
      when(subCommand.mock.run()).thenAnswer((i) {
        expect(subCommand.ref, isNotNull);
        return 42;
      });

      final result = await sut.run(['group', 'sub']);
      expect(result, 42);

      verify(subCommand.mock.run()).called(1);
    });

    test('applies overrides to scope', () async {
      when(command.mock.run()).thenAnswer((i) {
        expect(command.ref.read(scopedProvider), 11);
        expect(container.read(scopedProvider), 0);
        return 11;
      });

      container.lock(scopedProvider);
      expect(container.read(scopedProvider), 0);

      final result = await sut.run(['test']);
      expect(result, 11);

      expect(container.read(scopedProvider), 0);

      verify(command.mock.run()).called(1);
    });
  });
}
