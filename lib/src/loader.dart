/// Copyright 2021 Hieu Rocker
///
/// Licensed under the Apache License, Version 2.0 (the "License");
/// you may not use this file except in compliance with the License.
/// You may obtain a copy of the License at
///
///   http://www.apache.org/licenses/LICENSE-2.0
///
/// Unless required by applicable law or agreed to in writing, software
/// distributed under the License is distributed on an "AS IS" BASIS,
/// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
/// See the License for the specific language governing permissions and
/// limitations under the License.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

/// State of the loader in its lifecycle:
/// [init] -> [loading] <-> [error] or [loaded]
enum LoaderState {
  /// The default state of the loader
  init,

  /// The loader is loading
  loading,

  /// There has been an error while loading the resource
  error,

  /// The resource has been loaded
  loaded,
}

/// Signature for a function that creates a [Future].
typedef FutureProvider = Future<dynamic> Function();

/// Signature for a function that creates a [Widget] from [BuildContext],
/// [LoaderController] and [Widget]. The given [Widget] is provided via
/// [LoaderBuilder.child] for caching purpose.
typedef LoaderWidgetBuilder = Widget Function(
    BuildContext, LoaderController, Widget?);

/// A [Widget] that replace its content with different widgets depends on the
/// state of the loader.
///
/// {@tool snippet}
///
/// Example of simple LoaderBuilder:
///
/// ```dart
/// Widget build(BuildContext context) {
///   return Scaffold(
///     appBar: AppBar(title: const Text('Flutter Loader Demo')),
///     body: LoaderBuilder(
///       loader: () => Future.delayed(Duration(seconds: 3), () => 'Hello World'),
///       builder: (context, controller, child) {
///         switch(controller.state) {
///           case LoaderState.error:
///             return ElevatedButton(
///               child: 'Error: ${controller.error}.\n\nClick here to try again',
///               onPressed: () => controller.load(),
///             );
///           case LoaderState.loaded:
///             return Text('Loaded: ${controller.data}')
///           case LoaderState.init:
///           case LoaderState.loading:
///           default:
///             return CircularProgressIndicator();
///         }
///       }
///     ),
///   );
/// }
/// ```
/// {@end-tool}
class LoaderBuilder extends StatefulWidget {
  /// Provides a [Future] which will do the actual work for loading data.
  final FutureProvider loader;

  /// Builds UI with the given [LoaderController] context.
  final LoaderWidgetBuilder builder;

  /// The child widget which will be used by [builder] for caching purpose.
  final Widget? child;

  /// Whether the loader will load the data automatically in the beginning
  final bool autoLoad;

  LoaderBuilder({
    Key? key,
    required this.loader,
    required this.builder,
    this.child,
    this.autoLoad = true,
  }) : super(key: key);

  @override
  _LoaderBuilderState createState() => _LoaderBuilderState();
}

/// A controller for the loader.
///
/// You can access the controller in the descending tree with:
///
/// ```dart
/// final controller = LoaderController.of(context);
/// ```
abstract class LoaderController {
  /// Load the resource. If the resource is already loading, the call will
  /// return immediately with null.
  ///
  /// By default it will load the resource using [LoaderBuilder.loader]. You can
  /// provide a custom loader via [loader].
  ///
  /// Calling this method will clear the data of [error] and [errorStacktrace].
  Future<dynamic> load([Future<dynamic> Function() loader]);

  /// Current state of the loader.
  LoaderState get state;

  /// The data that is loaded successfully by the loader. This data will not
  /// be cleared when [load] is called.
  dynamic get data;

  /// The error that has happened while loading data. This data will be cleared
  /// when [load] is called.
  dynamic get error;

  /// Stacktrace of the error that has happened while loading data. This data
  /// will be cleared when [load] is called.
  StackTrace? get errorStacktrace;

  /// Whether there has been an error while loading data.
  bool get hasError;

  /// Retrieves the [LoaderController] in the closest ancestor element.
  static LoaderController? of(BuildContext? context) => context
      ?.dependOnInheritedWidgetOfExactType<_LoaderControllerScope>()
      ?.controller;
}

class _LoaderBuilderState extends State<LoaderBuilder>
    implements LoaderController {
  late LoaderState _state = LoaderState.init;

  dynamic _data;

  dynamic get data => _data;

  dynamic _error;

  StackTrace? _errorStacktrace;

  @override
  LoaderState get state => _state;

  set state(LoaderState newValue) {
    if (this.mounted) {
      setState(() {
        _state = newValue;
      });
    }
  }

  @override
  Future<dynamic> load([Future<dynamic> Function()? resource]) async {
    if (_state == LoaderState.loading) return null;

    _error = null;
    _errorStacktrace = null;
    state = LoaderState.loading;
    try {
      _data = await (resource?.call() ?? widget.loader.call());
      state = LoaderState.loaded;
      return _data;
    } catch (e, s) {
      _error = e;
      _errorStacktrace = s;
      state = LoaderState.error;
    }
    return _data;
  }

  @override
  dynamic get error => _error;

  @override
  StackTrace? get errorStacktrace => _errorStacktrace;

  @override
  bool get hasError => _error != null;

  @override
  void initState() {
    super.initState();
    if (widget.autoLoad) {
      Future.delayed(Duration.zero, () => load());
    }
  }

  @override
  Widget build(BuildContext context) {
    return _LoaderControllerScope(
      controller: this,
      child: widget.builder(context, this, widget.child),
    );
  }
}

class _LoaderControllerScope extends InheritedWidget {
  final LoaderController controller;

  _LoaderControllerScope({
    required this.controller,
    required Widget child,
  }) : super(child: child);

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => true;
}

/// A [Widget] that makes it easier to use [LoaderBuilder] by providing different
/// [WidgetBuilder] for different states in the loader's lifecycle.
///
/// {@tool snippet}
///
/// Example of a simple DefaultLoaderBuilder:
///
/// ```dart
/// @override
/// Widget build(BuildContext context) {
///   return Scaffold(
///     appBar: AppBar(
///       title: Text('Flutter Loader Demo'),
///     ),
///     body: DefaultLoaderBuilder(
///       themeData: DefaultLoaderThemeData(
///         errorMessageResolver: (error) =>
///         'Custom errorMessageResolver: $error',
///       ),
///       loader: () => Future.delayed(
///         Duration(seconds: 3),
///             () => 'Hello World',
///       ),
///       loadedBuilder: (context) {
///         return Center(
///           child: Column(
///             mainAxisAlignment: MainAxisAlignment.center,
///             children: [
///               Text('${LoaderController.of(context).data}'),
///               SizedBox(height: 10),
///               ElevatedButton(
///                 onPressed: () => LoaderController.of(context).load(
///                       () => Future.delayed(
///                       Duration(seconds: 3), () => Future.error('Oops')),
///                 ),
///                 child: Text('Error'),
///               ),
///               ElevatedButton(
///                 onPressed: () => LoaderController.of(context).load(),
///                 child: Text('Success'),
///               ),
///             ],
///           ),
///         );
///       },
///     ),
///   );
/// }
/// ```
/// {@end-tool}
class DefaultLoaderBuilder extends StatelessWidget {
  /// Provides a [Future] which will do the actual work for loading data.
  final FutureProvider loader;

  /// Builds widget for the state of [LoaderState.init]. Omit to use [defaultInitWidget].
  final WidgetBuilder? initBuilder;

  /// Builds widget for the state of [LoaderState.loading]. Omit to use [defaultLoadingWidget].
  final WidgetBuilder? loadingBuilder;

  /// Builds widget for the state of [LoaderState.error]. Omit to use [defaultErrorWidget].
  final WidgetBuilder? errorBuilder;

  /// Builds widget for the state of [LoaderState.loaded]. Omit to use [defaultLoadedWidget].
  final WidgetBuilder? loadedBuilder;

  /// Visual configuration for the default UI implementations.
  final DefaultLoaderThemeData? themeData;

  /// Callback function which will be called right after the controller is created.
  final void Function(LoaderController controller)? onControllerCreated;

  /// Callback function which will be called when the error occurs.
  final void Function(dynamic error, StackTrace stackTrace)? onError;

  /// Whether the loader will load the data automatically in the beginning
  final bool autoLoad;

  /// Creates a [DefaultLoaderBuilder] to handle resource loading using [loader]
  /// and show according UI for different state.
  DefaultLoaderBuilder({
    Key? key,
    required this.loader,
    this.initBuilder,
    this.loadingBuilder,
    this.errorBuilder,
    this.loadedBuilder,
    this.onControllerCreated,
    this.onError,
    this.themeData,
    this.autoLoad = true,
  }) : super(key: key);

  @override
  Widget build(_) {
    return _DefaultLoaderTheme(
      themeData: themeData,
      child: LoaderBuilder(
        loader: loader,
        autoLoad: autoLoad,
        builder: (context, controller, widget) => widget!,
        child: Builder(
          builder: (context) {
            final controller = LoaderController.of(context)!;
            onControllerCreated?.call(controller);
            final themeData = DefaultLoaderThemeData.of(context);
            if (themeData.transitionDuration.inMilliseconds == 0)
              return _buildContent(context, controller);

            return AnimatedSwitcher(
              duration: themeData.transitionDuration,
              child: Container(
                key: UniqueKey(),
                child: _buildContent(context, controller),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    LoaderController controller,
  ) {
    switch (controller.state) {
      case LoaderState.loading:
        return loadingBuilder?.call(context) ?? defaultLoadingWidget(context);
      case LoaderState.error:
        onError?.call(controller.error!, controller.errorStacktrace!);
        return errorBuilder?.call(context) ?? defaultErrorWidget(context);
      case LoaderState.loaded:
        return loadedBuilder?.call(context) ?? defaultLoadedWidget(context);
      case LoaderState.init:
      default:
        return initBuilder?.call(context) ?? defaultInitWidget(context);
    }
  }

  /// Default UI for [LoaderState.init].
  static Widget defaultInitWidget(BuildContext context) =>
      defaultLoadingWidget(context);

  /// Default UI for [LoaderState.loading].
  static Widget defaultLoadingWidget(BuildContext context) {
    final themeData = DefaultLoaderThemeData.of(context);
    return Center(
      child: SizedBox(
        width: themeData.loadingIndicatorSize,
        height: themeData.loadingIndicatorSize,
        child: CircularProgressIndicator(),
      ),
    );
  }

  /// Default UI for [LoaderState.error].
  static Widget defaultErrorWidget(BuildContext context) {
    final controller = LoaderController.of(context)!;
    final themeData = DefaultLoaderThemeData.of(context);
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        direction: themeData.errorLayoutDirection,
        children: [
          Text(
            themeData.errorMessageResolver.call(controller.error),
            textAlign: TextAlign.center,
          ),
          if (themeData.showRetryWhenError)
            SizedBox(
              height: themeData.errorSpacing,
              width: themeData.errorSpacing,
            ),
          if (themeData.showRetryWhenError)
            ElevatedButton(
              onPressed: () => controller.load(),
              child: Text(themeData.retryLabel),
            )
        ],
      ),
    );
  }

  /// Default UI for [LoaderState.loaded].
  static Widget defaultLoadedWidget(BuildContext context) {
    final controller = LoaderController.of(context)!;
    return Center(
        child: Text(
      '${controller.data}',
      textAlign: TextAlign.center,
    ));
  }
}

class _DefaultLoaderTheme extends InheritedWidget {
  final DefaultLoaderThemeData? themeData;

  const _DefaultLoaderTheme({required Widget child, this.themeData})
      : super(child: child);

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => true;
}

/// Defines the configuration of the overall visual [Theme] for a
/// [DefaultLoaderBuilder].
class DefaultLoaderThemeData {
  const DefaultLoaderThemeData({
    this.loadingIndicatorSize = 40.0,
    this.errorSpacing = 10.0,
    this.errorLayoutDirection = Axis.vertical,
    this.errorMessageResolver = defaultErrorMessageResolver,
    this.showRetryWhenError = true,
    this.retryLabel = 'Retry',
    this.transitionDuration = const Duration(milliseconds: 250),
  });

  /// Size of the [CircularProgressIndicator] in
  /// [DefaultLoaderBuilder.defaultInitWidget].
  final double loadingIndicatorSize;

  /// Spacing between the error message and the retry button in
  /// [DefaultLoaderBuilder.defaultErrorWidget].
  final double errorSpacing;

  /// Layout direction for the error message and the retry button in
  /// [DefaultLoaderBuilder.defaultErrorWidget].
  final Axis errorLayoutDirection;

  /// Resolves error message from a given error.
  ///
  /// Used in [DefaultLoaderBuilder.defaultErrorWidget].
  final ErrorMessageResolver errorMessageResolver;

  /// Whether to show the retry button when there is an error.
  ///
  /// Used in [DefaultLoaderBuilder.defaultErrorWidget].
  final bool showRetryWhenError;

  /// Label for the retry button when there is an error.
  ///
  /// Used in [DefaultLoaderBuilder.defaultErrorWidget].
  final String retryLabel;

  /// Duration for the UI transition between different [LoaderState]. Set to `0`
  /// will disable the transition animation.
  final Duration transitionDuration;

  /// Retrieves the [DefaultLoaderThemeData] in the closest ancestor element.
  static DefaultLoaderThemeData of(BuildContext? context) =>
      context
          ?.dependOnInheritedWidgetOfExactType<_DefaultLoaderTheme>()
          ?.themeData ??
      defaultData;

  /// The default visual configuration for [DefaultLoaderBuilder].
  static const defaultData = DefaultLoaderThemeData();
}

/// Signature for a function that converts an error into a [String].
typedef ErrorMessageResolver = String Function(dynamic error);

/// The default [ErrorMessageResolver].
String defaultErrorMessageResolver(dynamic error) {
  String? message;
  try {
    message = error.message;
  } catch (e) {}
  return message ?? '$error';
}
