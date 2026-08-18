import 'package:flutter/material.dart';

/// Global scaffold key for the top-level AppShell so nested screens can open the
/// drawer (avoids needing the nearest Scaffold).
final GlobalKey<ScaffoldState> appShellScaffoldKey = GlobalKey<ScaffoldState>();
