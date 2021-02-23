# flutter_loader

![Latest version on pub.dev](https://shields.io/pub/v/flutter_loader)

A Flutter package for simplifying resource loading.

## Getting Started

Import the library with

```dart
import 'package:flutter_loader/flutter_loader.dart';
```

Then you can build a UI for loading resource with

```dart
LoaderBuilder(
    loader: () async {
        await _loadResourceAsync();
    },
    builder: (context, controller, widget) {
        return _buildContent(context, controller, widget);
    }
)
```

Or use `DefaultLoaderBuilder` with default UI implementation:

```dart
DefaultLoaderBuilder(
    loader: () => _loadResourceAsync(),
)
```

`DefaulLoaderBuilder` offers UI for the full lifecycle of the loader:
- **init**: show loading indicator
- **loading**: show loading indicator
- **error**: show an error message and a button for retrying
- **loaded**: show a text message displaying the loaded data

You can optional provide `initBuilder`, `loadingBuilder`, `errorBuilder`, `loadedBuilder` to
customize the UI for each of the above states. You can also customize the style of
`DefaultLoaderBuilder` by providing `DefaultLoaderThemeData` via `themeData`.
