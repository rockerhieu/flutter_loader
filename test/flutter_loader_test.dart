import 'package:flutter/material.dart';
import 'package:flutter_loader/flutter_loader.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('flutter_loader', () {
    testWidgets('LoaderBuilder', (tester) async {
      LoaderController loaderController;
      int count = 0;
      final futures = <Future Function()>[
        () => Future.value('Hello World'),
        () => Future.error('Oops'),
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoaderBuilder(
                loader: () =>
                    Future.delayed(Duration(seconds: 1), futures[count++]),
                builder: (context, controller, widget) {
                  loaderController = controller;
                  return FlatButton(
                    child: Text('${controller.data}'),
                    onPressed: () => controller.load(),
                  );
                }),
          ),
        ),
      );
      expect(loaderController.state, LoaderState.init);
      await tester.pumpAndSettle();
      expect(loaderController.state, LoaderState.loading);
      await tester.pump(Duration(seconds: 2));
      expect(find.text('Hello World'), findsOneWidget);
      expect(loaderController.data, 'Hello World');
      expect(loaderController.state, LoaderState.loaded);

      await tester.tap(find.text('Hello World'));
      await tester.pumpAndSettle();
      expect(loaderController.state, LoaderState.loading);
      await tester.pump(Duration(seconds: 2));
      expect(find.text('Hello World'), findsOneWidget);
      expect(loaderController.data, 'Hello World');
      expect(loaderController.state, LoaderState.error);
      expect(loaderController.error, 'Oops');
    });
  });
}
