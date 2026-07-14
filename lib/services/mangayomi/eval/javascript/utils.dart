import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_js/flutter_js.dart';
import 'package:http/http.dart' as http;
import 'package:js_packer/js_packer.dart';
import 'package:zenbu/services/mangayomi/eval/model/m_bridge.dart';
import 'package:zenbu/services/mangayomi/webview_server.dart';

class JsUtils {
  final JavascriptRuntime runtime;
  JsUtils(this.runtime);

  void init() {
    runtime.onMessage('log', (dynamic args) {
      if (kDebugMode) {
        debugPrint("[JS LOG]: ${args[0]}");
      }
      return null;
    });

    runtime.onMessage('cryptoHandler', (dynamic args) {
      final text = args[0] as String;
      final iv = args[1] as String;
      final key = args[2] as String;
      final isEncrypt = args[3] as bool;
      return MBridge.cryptoHandler(text, iv, key, isEncrypt);
    });

    runtime.onMessage('encryptAESCryptoJS', (dynamic args) {
      final text = args[0] as String;
      final passphrase = args[1] as String;
      return MBridge.encryptAESCryptoJS(text, passphrase);
    });

    runtime.onMessage('decryptAESCryptoJS', (dynamic args) {
      final encrypted = args[0] as String;
      final passphrase = args[1] as String;
      return MBridge.decryptAESCryptoJS(encrypted, passphrase);
    });

    runtime.onMessage('deobfuscateJsPassword', (dynamic args) {
      return MBridge.deobfuscateJsPassword(args[0] as String);
    });

    runtime.onMessage('unpackJsAndCombine', (dynamic args) {
      return MBridge.unpackJsAndCombine(args[0] as String) ?? "";
    });

    runtime.onMessage('unpackJs', (dynamic args) {
      try {
        final jsPacker = JSPacker(args[0] as String);
        return jsPacker.unpack() ?? "";
      } catch (_) {
        return "";
      }
    });

    runtime.onMessage('parseDates', (dynamic args) {
      return MBridge.parseDates(
        args[0] as List,
        args[1] as String,
        args[2] as String,
      );
    });

    runtime.onMessage('native_b64dec', (dynamic args) {
      try {
        final String str = args[0] as String;
        final normalized = str.replaceAll('-', '+').replaceAll('_', '/');
        final padded = normalized.padRight(
          normalized.length + (4 - normalized.length % 4) % 4,
          '=',
        );
        final bytes = base64.decode(padded);
        return json.encode(bytes);
      } catch (_) {
        return '[]';
      }
    });

    runtime.onMessage('native_inflate', (dynamic args) {
      try {
        final List<dynamic> list = args[0] as List;
        final bytes = list.map((e) => e as int).toList();
        final decompressed = gzip.decode(bytes);
        return json.encode(decompressed);
      } catch (_) {
        return '[]';
      }
    });

    runtime.onMessage('evaluateJavascriptViaWebview', (dynamic args) async {
      try {
        await ensureWebViewServerStarted();
        if (cfPort == 0) return false;
        final response = await http.post(
          Uri.parse('http://localhost:$cfPort/evaluateJavascriptViaWebview'),
          headers: {HttpHeaders.contentTypeHeader: 'application/json'},
          body: jsonEncode({
            'url': args[0],
            'headers': (args[1] is Map)
                ? Map<String, String>.from(args[1] as Map)
                : <String, String>{},
            'scripts': (args[2] is List)
                ? (args[2] as List).map((e) => e.toString()).toList()
                : <String>[],
            'time': args.length > 3 ? args[3] : 30,
          }),
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          return data['result'];
        }
      } catch (_) {}
      return false;
    });

    runtime.onMessage('parseEpub', (dynamic args) async {
      return "{}";
    });

    runtime.onMessage('parseEpubChapter', (dynamic args) async {
      return "";
    });

    runtime.evaluate('''
      console = {
        log: function(msg) {
          if (typeof msg === 'object') msg = JSON.stringify(msg);
          sendMessage('log', JSON.stringify([msg]));
        },
        warn: function(msg) {
          if (typeof msg === 'object') msg = JSON.stringify(msg);
          sendMessage('log', JSON.stringify([msg]));
        },
        error: function(msg) {
          if (typeof msg === 'object') msg = JSON.stringify(msg);
          sendMessage('log', JSON.stringify([msg]));
        }
      };

      String.prototype.substringAfter = function(pattern) {
        const startIndex = this.indexOf(pattern);
        if (startIndex === -1) return this.substring(0);

        const start = startIndex + pattern.length;
        return this.substring(start);
      };

      String.prototype.substringAfterLast = function(pattern) {
        return this.split(pattern).pop();
      };

      String.prototype.substringBefore = function(pattern) {
        const endIndex = this.indexOf(pattern);
        if (endIndex === -1) return this.substring(0);

        return this.substring(0, endIndex);
      };

      String.prototype.substringBeforeLast = function(pattern) {
        const endIndex = this.lastIndexOf(pattern);
        if (endIndex === -1) return this.substring(0);
        return this.substring(0, endIndex);
      };

      String.prototype.substringBetween = function(left, right) {
        let startIndex = 0;
        let index = this.indexOf(left, startIndex);
        if (index === -1) return "";
        let leftIndex = index + left.length;
        let rightIndex = this.indexOf(right, leftIndex);
        if (rightIndex === -1) return "";
        startIndex = rightIndex + right.length;
        return this.substring(leftIndex, rightIndex);
      };

      function cryptoHandler(text, iv, secretKeyString, encrypt) {
        return sendMessage("cryptoHandler", JSON.stringify([text, iv, secretKeyString, encrypt]));
      }

      function encryptAESCryptoJS(plainText, passphrase) {
        return sendMessage("encryptAESCryptoJS", JSON.stringify([plainText, passphrase]));
      }

      function decryptAESCryptoJS(encrypted, passphrase) {
        return sendMessage("decryptAESCryptoJS", JSON.stringify([encrypted, passphrase]));
      }

      function deobfuscateJsPassword(inputString) {
        return sendMessage("deobfuscateJsPassword", JSON.stringify([inputString]));
      }

      function unpackJsAndCombine(scriptBlock) {
        return sendMessage("unpackJsAndCombine", JSON.stringify([scriptBlock]));
      }

      function unpackJs(packedJS) {
        return sendMessage("unpackJs", JSON.stringify([packedJS]));
      }

      function parseDates(value, dateFormat, dateFormatLocale) {
        return sendMessage("parseDates", JSON.stringify([value, dateFormat, dateFormatLocale]));
      }

      async function evaluateJavascriptViaWebview(url, headers, scripts) {
        return await sendMessage("evaluateJavascriptViaWebview", JSON.stringify([url, headers, scripts]));
      }

      async function parseEpub(bookName, url, headers) {
        return JSON.parse(await sendMessage("parseEpub", JSON.stringify([bookName, url, headers])));
      }

      async function parseEpubChapter(bookName, url, headers, chapterTitle) {
        return await sendMessage("parseEpubChapter", JSON.stringify([bookName, url, headers, chapterTitle]));
      }
    ''');
  }
}
