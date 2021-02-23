import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

enum LoaderState {
  init,
  loading,
  error,
  loaded,
}

typedef FutureProvider = Future<dynamic> Function();
typedef LoaderWidgetBuilder = Widget Function(
    BuildContext, LoaderController, Widget);

class LoaderBuilder extends StatefulWidget {
  final FutureProvider loader;
  final LoaderWidgetBuilder builder;
  final Widget child;
  final bool autoLoad;

  LoaderBuilder({
    Key key,
    @required this.loader,
    @required this.builder,
    this.child,
    this.autoLoad = true,
  }) : super(key: key);

  @override
  _LoaderBuilderState createState() => _LoaderBuilderState();
}

abstract class LoaderController {
  Future<dynamic> load([Future<dynamic> Function() resource]);

  LoaderState get state;

  dynamic get data;

  dynamic get error;

  dynamic get errorStacktrace;

  bool get hasError;

  static LoaderController of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<_LoaderControllerScope>();
    return scope?.controller;
  }
}

class _LoaderBuilderState extends State<LoaderBuilder>
    implements LoaderController {
  var _state = LoaderState.init;

  dynamic _data;

  dynamic get data => _data;

  var _error;
  StackTrace _errorStacktrace;

  @override
  LoaderState get state => _state;

  set state(LoaderState newValue) {
    setState(() {
      _state = newValue;
    });
  }

  @override
  Future<dynamic> load([Future<dynamic> Function() resource]) async {
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
  StackTrace get errorStacktrace => _errorStacktrace;

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
    @required this.controller,
    @required Widget child,
  }) : super(child: child);

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => true;
}

class DefaultLoaderBuilder extends StatelessWidget {
  final FutureProvider loader;
  final WidgetBuilder initBuilder;
  final WidgetBuilder loadingBuilder;
  final WidgetBuilder errorBuilder;
  final WidgetBuilder loadedBuilder;

  DefaultLoaderBuilder({
    Key key,
    @required this.loader,
    this.initBuilder,
    this.loadingBuilder,
    this.errorBuilder,
    this.loadedBuilder,
  }) : super(key: key) {
    assert(loader != null, 'loader must not be null');
  }

  @override
  Widget build(_) {
    return LoaderBuilder(
      loader: loader,
      builder: (context, controller, widget) => widget,
      child: Builder(
        builder: (context) {
          final controller = LoaderController.of(context);
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
    );
  }

  Widget _buildContent(
    BuildContext context,
    LoaderController controller,
  ) {
    switch (controller.state) {
      case LoaderState.loading:
        return loadingBuilder?.call(context) ?? _defaultLoadingWidget(context);
      case LoaderState.error:
        return errorBuilder?.call(context) ?? _defaultErrorWidget(context);
      case LoaderState.loaded:
        return loadedBuilder?.call(context) ?? _defaultLoadedWidget(context);
      case LoaderState.init:
      default:
        return initBuilder?.call(context) ?? _defaultInitWidget(context);
    }
  }

  static Widget _defaultInitWidget(BuildContext context) =>
      _defaultLoadingWidget(context);

  static Widget _defaultLoadingWidget(BuildContext context) {
    final themeData = DefaultLoaderThemeData.of(context);
    return Center(
      child: SizedBox(
        width: themeData.loadingIndicatorSize,
        height: themeData.loadingIndicatorSize,
        child: CircularProgressIndicator(),
      ),
    );
  }

  static Widget _defaultErrorWidget(BuildContext context) {
    final controller = LoaderController.of(context);
    final themeData = DefaultLoaderThemeData.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            themeData.errorMessageResolver.call(controller.error),
            textAlign: TextAlign.center,
          ),
          if (themeData.showRetryWhenError)
            SizedBox(height: themeData.errorSpacing),
          if (themeData.showRetryWhenError)
            RaisedButton(
              onPressed: () => controller.load(),
              child: Text(themeData.retryLabel),
            )
        ],
      ),
    );
  }

  static Widget _defaultLoadedWidget(BuildContext context) {
    final controller = LoaderController.of(context);
    return Center(
        child: Text(
      '${controller.data}',
      textAlign: TextAlign.center,
    ));
  }
}

class DefaultLoaderThemeData extends InheritedWidget {
  const DefaultLoaderThemeData({
    Widget child,
    this.loadingIndicatorSize = 40.0,
    this.errorSpacing = 10.0,
    this.errorLayoutDirection = Axis.vertical,
    this.errorMessageResolver = defaultErrorMessageResolver,
    this.showRetryWhenError = true,
    this.retryLabel = 'Retry',
    this.transitionDuration = const Duration(milliseconds: 250),
  }) : super(child: child);

  final double loadingIndicatorSize;
  final double errorSpacing;
  final Axis errorLayoutDirection;
  final ErrorMessageResolver errorMessageResolver;
  final bool showRetryWhenError;
  final String retryLabel;
  final Duration transitionDuration;

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => true;

  static DefaultLoaderThemeData of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DefaultLoaderThemeData>() ??
      defaultData;

  static const defaultData = DefaultLoaderThemeData();
}

typedef ErrorMessageResolver = String Function(dynamic error);

String defaultErrorMessageResolver(dynamic error) {
  String message;
  try {
    message = error.message;
  } catch (e) {}
  return message ?? '$error';
}
