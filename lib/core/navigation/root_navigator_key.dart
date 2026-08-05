import 'package:flutter/widgets.dart';

/// Lets code with no [BuildContext] of its own — notably a tapped system
/// notification's callback, which fires from the OS, not from any widget's
/// event handler — push a route. Set as `MaterialApp.navigatorKey` in
/// `app.dart`.
final rootNavigatorKey = GlobalKey<NavigatorState>();
