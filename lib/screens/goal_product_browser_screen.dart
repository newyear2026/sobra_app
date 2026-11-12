import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../l10n/generated/app_localizations.dart';
import '../services/goal_product_import.dart';
import '../theme/app_theme.dart';
import '../widgets/pixel_ui.dart';

Future<GoalProductImport?> openGoalProductBrowser(
  BuildContext context,
  String url,
) => Navigator.of(context).push<GoalProductImport>(
  MaterialPageRoute(builder: (_) => GoalProductBrowserScreen(url: url)),
);

/// The real shopping site remains visible. Native controls only read the
/// product when asked; neither navigation nor a finished challenge saves it.
class GoalProductBrowserScreen extends StatefulWidget {
  const GoalProductBrowserScreen({super.key, required this.url});

  final String url;

  @override
  State<GoalProductBrowserScreen> createState() =>
      _GoalProductBrowserScreenState();
}

enum _BrowserNotice { invalid, unsupported, failed, verification, noProduct }

class _GoalProductBrowserScreenState extends State<GoalProductBrowserScreen> {
  WebViewController? _controller;
  Uri? _current;
  _BrowserNotice? _notice;
  int _progress = 0;
  int _navigation = 0;
  bool _reading = false;
  bool _initialized = false;

  // A popped route stays mounted during its exit animation. An inspection
  // finishing then must not pop the goal editor underneath it.
  bool get _isCurrent => mounted && ModalRoute.of(context)?.isCurrent == true;

  @override
  void initState() {
    super.initState();
    _current = safeGoalUrl(widget.url);
    if (_current == null) {
      _notice = _BrowserNotice.invalid;
    } else if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      _notice = _BrowserNotice.unsupported;
    } else {
      unawaited(_initialize());
    }
  }

  Future<void> _initialize() async {
    try {
      final controller = WebViewController();
      await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      await controller.setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) => safeGoalUrl(request.url) == null
              ? NavigationDecision.prevent
              : NavigationDecision.navigate,
          onPageStarted: (url) {
            if (!mounted) return;
            setState(() {
              _current = safeGoalUrl(url) ?? _current;
              _progress = 0;
              _navigation++;
              _notice = null;
            });
          },
          onProgress: (value) {
            if (mounted) setState(() => _progress = value);
          },
          onPageFinished: (url) {
            if (!mounted) return;
            setState(() {
              _current = safeGoalUrl(url) ?? _current;
              _progress = 100;
            });
          },
          onWebResourceError: (error) {
            if (mounted && error.isForMainFrame == true) {
              setState(() => _notice = _BrowserNotice.failed);
            }
          },
        ),
      );
      if (!mounted) return;
      setState(() {
        _controller = controller;
        _initialized = true;
      });
      await controller.loadRequest(_current!);
    } on Object {
      if (mounted) setState(() => _notice = _BrowserNotice.failed);
    }
  }

  Future<void> _retry() async {
    if (_reading) return;
    setState(() {
      _notice = null;
      _progress = 0;
    });
    if (_controller == null) {
      await _initialize();
      return;
    }
    try {
      await _controller!.reload();
    } on Object {
      if (mounted) setState(() => _notice = _BrowserNotice.failed);
    }
  }

  Future<void> _readProduct() async {
    final controller = _controller;
    if (controller == null || _reading || !_isCurrent) return;
    final navigation = _navigation;
    setState(() {
      _reading = true;
      _notice = null;
    });
    try {
      final raw = await controller
          .runJavaScriptReturningResult(goalProductExtractionScript)
          .timeout(const Duration(seconds: 12));
      final product = parseGoalProductPayload(raw);
      final currentUrl = safeGoalUrl(await controller.currentUrl());
      if (!mounted || !_isCurrent) return;
      // A page can redirect or the user can navigate while JS is in flight.
      // Never return one product with another page's address.
      if (navigation != _navigation ||
          product == null ||
          currentUrl?.toString() != product.sourceUrl) {
        setState(() => _notice = _BrowserNotice.noProduct);
        return;
      }
      Navigator.of(context).pop(product);
    } on GoalProductVerificationRequired {
      if (_isCurrent) setState(() => _notice = _BrowserNotice.verification);
    } on Object {
      if (_isCurrent) setState(() => _notice = _BrowserNotice.noProduct);
    } finally {
      if (_isCurrent) setState(() => _reading = false);
    }
  }

  String? _message(AppLocalizations l10n) => switch (_notice) {
    _BrowserNotice.invalid => l10n.goalInvalidLink,
    _BrowserNotice.unsupported => l10n.goalBrowserUnsupported,
    _BrowserNotice.failed => l10n.goalBrowserLoadFailed,
    _BrowserNotice.verification => l10n.goalBrowserVerification,
    _BrowserNotice.noProduct => l10n.goalBrowserNoProduct,
    null => null,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final message = _message(l10n);
    final controller = _controller;
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: Text(l10n.goalBrowserTitle)),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_current != null)
                    Row(
                      children: [
                        const Icon(Icons.lock_outline, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _current!.host,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: pixelText(size: 13, bold: true),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.goalBrowserInstructions,
                    style: pixelText(size: 13, color: AppColors.inkSoft),
                  ),
                ],
              ),
            ),
            if (_initialized && _progress < 100)
              LinearProgressIndicator(
                value: _progress / 100,
                semanticsLabel: l10n.goalBrowserLoading,
              ),
            Expanded(
              child: controller == null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          message ?? l10n.goalBrowserLoading,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : WebViewWidget(controller: controller),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  top: BorderSide(color: AppColors.ink, width: 2.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (message != null && controller != null) ...[
                    Text(
                      message,
                      style: pixelText(size: 13, color: AppColors.inkSoft),
                      key: const ValueKey('goal-browser-notice'),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (_notice == _BrowserNotice.failed)
                    PixelButton(
                      label: l10n.goalBrowserRetry,
                      onPressed: _reading ? null : _retry,
                    ),
                  if (controller != null && _notice != _BrowserNotice.failed)
                    PixelButton(
                      label: l10n.goalBrowserRead,
                      onPressed: _reading ? null : _readProduct,
                      icon: _reading ? Icons.hourglass_top : Icons.check,
                      maxLines: 2,
                    ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.goalBrowserManual),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
