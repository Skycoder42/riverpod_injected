import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:test/test.dart';

extension ProviderContainerX on ProviderContainer {
  void Function() lock(ProviderListenable<dynamic> provider) {
    final sub = listen(provider, (_, _) {});
    addTearDown(sub.close);
    return sub.close;
  }
}
