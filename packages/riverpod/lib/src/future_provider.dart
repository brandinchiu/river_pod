import 'dart:async';

import 'package:meta/meta.dart';

import 'async_provider/auto_dispose.dart';
import 'async_provider/base.dart';
import 'async_value_converters.dart';
import 'builders.dart';
import 'common.dart';
import 'framework.dart';
import 'provider.dart';
import 'stream_provider.dart';
import 'value_provider.dart';

part 'future_provider/auto_dispose.dart';
part 'future_provider/base.dart';

/// {@template riverpod.futureprovider}
/// A provider that asynchronously creates a single value.
///
/// [FutureProvider] can be considered as a combination of [Provider] and
/// `FutureBuilder`.
/// By using [FutureProvider], the UI will be able to read the state of the
/// future synchronously, handle the loading/error states, and rebuild when the
/// future completes.
///
/// A common use-case for [FutureProvider] is to represent an asynchronous operation
/// such as reading a file or making an HTTP request, that is then listened by the UI.
///
/// It can then be combined with:
/// - [FutureProvider.family], for parameterizing the http request based on external
///   parameters, such as fetching a `User` from its id.
/// - [FutureProvider.autoDispose], to cancel the HTTP request if the user
///   leaves the screen before the [Future] completed.
///
/// ## Usage example: reading a configuration file
///
/// [FutureProvider] can be a convenient way to expose a `Configuration` object
/// created by reading a JSON file.
///
/// Creating the configuration would be done with your typical async/await
/// syntax, but inside the provider.
/// Using Flutter's asset system, this would be:
///
/// ```dart
/// final configProvider = FutureProvider<Configuration>((ref) async {
///   final content = json.decode(
///     await rootBundle.loadString('assets/configurations.json'),
///   ) as Map<String, Object?>;
///
///   return Configuration.fromJson(content);
/// });
/// ```
///
/// Then, the UI can listen to configurations like so:
///
/// ```dart
/// Widget build(BuildContext context, WidgetRef ref) {
///   AsyncValue<Configuration> config = ref.watch(configProvider);
///
///   return config.when(
///     loading: (_) => const CircularProgressIndicator(),
///     error: (err, stack) => Text('Error: $err'),
///     data: (config) {
///       return Text(config.host);
///     },
///   );
/// }
/// ```
///
/// This will automatically rebuild the UI when the [Future] completes.
///
/// As you can see, listening to a [FutureProvider] inside a widget returns
/// an [AsyncValue] – which allows handling the error/loading states.
///
/// See also:
///
/// - [Provider], a provider that synchronously creates a value
/// - [StreamProvider], a provider that asynchronously expose a value which
///   can change over time.
/// - [FutureProvider.family], to create a [FutureProvider] from external parameters
/// - [FutureProvider.autoDispose], to destroy the state of a [FutureProvider] when no-longer needed.
/// {@endtemplate}
AsyncValue<State> _listenFuture<State>(
  Future<State> Function() future,
  ProviderElementBase<AsyncValue<State>> ref,
) {
  var running = true;
  ref.onDispose(() => running = false);
  try {
    ref.setState(AsyncValue<State>.loading());
    future().then(
      (event) {
        if (running) ref.setState(AsyncValue<State>.data(event));
      },
      // ignore: avoid_types_on_closure_parameters
      onError: (Object err, StackTrace stack) {
        if (running) ref.setState(AsyncValue<State>.error(err, stack));
      },
    );

    return ref.getState()!;
  } catch (err, stack) {
    return AsyncValue.error(err, stack);
  }
}
