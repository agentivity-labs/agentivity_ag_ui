import 'package:flutter/material.dart';

/// Global theme-mode notifier — toggled from any screen.
final themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.system);
