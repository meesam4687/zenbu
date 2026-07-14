import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

int cfPort = 0;
HttpServer? _server;

Future<void> ensureWebViewServerStarted() async {
  if (cfPort != 0) return;
  if (kIsWeb) return;
  _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  cfPort = _server!.port;
  _server!.listen(_handleRequest);
}

Future<void> _handleRequest(HttpRequest request) async {
  if (request.method != 'POST') {
    request.response.statusCode = 405;
    await request.response.close();
    return;
  }
  final body = await utf8.decoder.bind(request).join();
  final data = jsonDecode(body) as Map<String, dynamic>;

  if (request.uri.path == '/evaluateJavascriptViaWebview') {
    final result = await _evaluateJavascript(data);
    request.response
      ..statusCode = 200
      ..headers.contentType = ContentType.json
      ..write(jsonEncode({'result': result}));
  } else if (request.uri.path == '/resolve_cf') {
    final result = await _resolveCf(data);
    request.response
      ..statusCode = 200
      ..headers.contentType = ContentType.json
      ..write(jsonEncode({'result': result}));
  } else {
    request.response.statusCode = 404;
  }
  await request.response.close();
}

Future<dynamic> _evaluateJavascript(Map<String, dynamic> data) async {
  final url = data['url'] as String;
  final headers = (data['headers'] as Map?)?.cast<String, String>() ?? {};
  final scripts = (data['scripts'] as List?)?.cast<String>() ?? [];
  final timeoutSec = (data['time'] as int?) ?? 30;

  String response = '';
  bool isOk = false;

  HeadlessInAppWebView? webView;
  webView = HeadlessInAppWebView(
    initialUrlRequest: URLRequest(url: WebUri(url), headers: headers),
    onWebViewCreated: (controller) {
      controller.addJavaScriptHandler(
        handlerName: 'setResponse',
        callback: (args) {
          response = args.isNotEmpty ? args[0].toString() : '';
          isOk = true;
        },
      );
    },
    onLoadStop: (controller, loadedUrl) async {
      for (final script in scripts) {
        try {
          await controller.evaluateJavascript(source: script);
        } catch (_) {}
      }
    },
  );

  try {
    await webView.run();
    final deadline = DateTime.now().add(Duration(seconds: timeoutSec));
    while (!isOk && DateTime.now().isBefore(deadline)) {
      await Future.delayed(const Duration(milliseconds: 300));
    }
  } finally {
    await webView.dispose();
  }

  return isOk ? response : false;
}

Future<bool> _resolveCf(Map<String, dynamic> data) async {
  final url = data['url'] as String;
  final completer = Completer<bool>();
  bool resolved = false;

  HeadlessInAppWebView? webView;
  webView = HeadlessInAppWebView(
    initialUrlRequest: URLRequest(url: WebUri(url)),
    onLoadStop: (controller, loadedUrl) async {
      final deadline = DateTime.now().add(const Duration(seconds: 15));
      while (DateTime.now().isBefore(deadline)) {
        try {
          final result = await controller.evaluateJavascript(
            source:
                "document.head.innerHTML.includes('#challenge-success-text')",
          );
          if (result == true || result == 'true') {
            resolved = true;
            break;
          }
        } catch (_) {}
        await Future.delayed(const Duration(milliseconds: 300));
      }
      if (!completer.isCompleted) completer.complete(resolved);
    },
  );

  try {
    await webView.run();
    return await completer.future.timeout(
      const Duration(seconds: 20),
      onTimeout: () => false,
    );
  } finally {
    await webView.dispose();
  }
}
