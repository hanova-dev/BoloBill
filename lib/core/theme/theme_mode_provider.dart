import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The shop's active theme. Defaults to light; the D3 settings screen (dark
/// theme toggle) will persist this once the settings module is built.
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);
