import 'dart:async';

import 'package:flutter/material.dart';

/// Keeps the application behind its required startup prerequisites.
class AppBootstrap extends StatefulWidget {
  const AppBootstrap({
    super.key,
    required this.initialize,
    required this.child,
    this.onInitializationFailure,
  });

  final Future<void> Function() initialize;
  final Widget child;

  /// Called after the error screen is rendered, for example to remove a
  /// preserved native splash without exposing an uninitialized application.
  final VoidCallback? onInitializationFailure;

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

enum _BootstrapStatus { loading, failed, ready }

class _AppBootstrapState extends State<AppBootstrap> {
  _BootstrapStatus _status = _BootstrapStatus.loading;

  @override
  void initState() {
    super.initState();
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    try {
      await widget.initialize();
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'Expensee startup',
          context: ErrorDescription('while initializing Expensee'),
        ),
      );
      if (!mounted) return;

      setState(() => _status = _BootstrapStatus.failed);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _status == _BootstrapStatus.failed) {
          widget.onInitializationFailure?.call();
        }
      });
      return;
    }

    if (!mounted) return;
    setState(() => _status = _BootstrapStatus.ready);
  }

  void _retry() {
    setState(() => _status = _BootstrapStatus.loading);
    unawaited(_initialize());
  }

  @override
  Widget build(BuildContext context) {
    if (_status == _BootstrapStatus.ready) return widget.child;

    return MaterialApp(
      title: 'Expensee',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _status == _BootstrapStatus.loading
                  ? const CircularProgressIndicator()
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 48),
                        const SizedBox(height: 16),
                        const Text(
                          'Unable to start Expensee. Please try again.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: _retry,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
