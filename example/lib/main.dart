import 'package:flutter/material.dart';
import 'package:flutter_loader/flutter_loader.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: LoaderDemo(),
    );
  }
}

class LoaderDemo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flutter Loader Demo'),
      ),
      body: DefaultLoaderBuilder(
        themeData: DefaultLoaderThemeData(
          errorMessageResolver: (error) =>
              'Custom errorMessageResolver: $error',
        ),
        loader: () => Future.delayed(
          Duration(seconds: 3),
          () => 'Hello World',
        ),
        loadedBuilder: (context) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('${LoaderController.of(context).data}'),
                SizedBox(height: 10),
                RaisedButton(
                  onPressed: () => LoaderController.of(context).load(
                    () => Future.delayed(
                        Duration(seconds: 3), () => Future.error('Oops')),
                  ),
                  child: Text('Error'),
                ),
                RaisedButton(
                  onPressed: () => LoaderController.of(context).load(),
                  child: Text('Success'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
