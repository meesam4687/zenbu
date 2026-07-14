import 'dart:convert';
import 'package:flutter_js/flutter_js.dart';
import 'package:http/http.dart' as http;
import 'package:zenbu/services/mangayomi/eval/javascript/service.dart';

class JsHttpClient {
  final JavascriptRuntime runtime;
  final JsExtensionService? service;
  JsHttpClient(this.runtime, {this.service});

  void init() {
    runtime.onMessage('http_head', (dynamic args) async {
      return await _toHttpResponse("HEAD", args);
    });
    runtime.onMessage('http_get', (dynamic args) async {
      return await _toHttpResponse("GET", args);
    });
    runtime.onMessage('http_post', (dynamic args) async {
      return await _toHttpResponse("POST", args);
    });
    runtime.onMessage('http_put', (dynamic args) async {
      return await _toHttpResponse("PUT", args);
    });
    runtime.onMessage('http_delete', (dynamic args) async {
      return await _toHttpResponse("DELETE", args);
    });
    runtime.onMessage('http_patch', (dynamic args) async {
      return await _toHttpResponse("PATCH", args);
    });

    runtime.evaluate('''
      class Client {
        constructor(reqcopyWith) {
          this.reqcopyWith = reqcopyWith;
        }
        _extractHeaders(optionsOrHeaders) {
          let headers = optionsOrHeaders || {};
          if (optionsOrHeaders && optionsOrHeaders.headers && typeof optionsOrHeaders.headers === 'object') {
            headers = optionsOrHeaders.headers;
          }
          return headers;
        }
        _extractBody(optionsOrHeaders, body) {
          let reqBody = body || "";
          if (optionsOrHeaders && typeof optionsOrHeaders === 'object') {
            if (optionsOrHeaders.body !== undefined) {
              reqBody = optionsOrHeaders.body;
            }
          }
          return reqBody;
        }
        _mergeExtHeaders(url, headers) {
          let merged = headers || {};
          if (typeof extension !== 'undefined' && typeof extension.getHeaders === 'function') {
            try {
              const extHeaders = extension.getHeaders(url);
              if (extHeaders && typeof extHeaders === 'object') {
                merged = Object.assign({}, extHeaders, merged);
              }
            } catch(e) {
              console.log("Error getting extension headers: " + e);
            }
          }
          return merged;
        }
        async head(url, optionsOrHeaders) {
          let headers = this._extractHeaders(optionsOrHeaders);
          headers = this._mergeExtHeaders(url, headers);
          const result = await sendMessage(
            "http_head",
            JSON.stringify([null, this.reqcopyWith, url, headers])
          );
          return JSON.parse(result);
        }
        async get(url, optionsOrHeaders) {
          let headers = this._extractHeaders(optionsOrHeaders);
          headers = this._mergeExtHeaders(url, headers);
          const result = await sendMessage(
            "http_get",
            JSON.stringify([null, this.reqcopyWith, url, headers])
          );
          return JSON.parse(result);
        }
        async post(url, optionsOrHeaders, body) {
          let headers = this._extractHeaders(optionsOrHeaders);
          headers = this._mergeExtHeaders(url, headers);
          const reqBody = this._extractBody(optionsOrHeaders, body);
          const result = await sendMessage(
            "http_post",
            JSON.stringify([null, this.reqcopyWith, url, headers, reqBody])
          );
          return JSON.parse(result);
        }
        async put(url, optionsOrHeaders, body) {
          let headers = this._extractHeaders(optionsOrHeaders);
          headers = this._mergeExtHeaders(url, headers);
          const reqBody = this._extractBody(optionsOrHeaders, body);
          const result = await sendMessage(
            "http_put",
            JSON.stringify([null, this.reqcopyWith, url, headers, reqBody])
          );
          return JSON.parse(result);
        }
        async delete(url, optionsOrHeaders, body) {
          let headers = this._extractHeaders(optionsOrHeaders);
          headers = this._mergeExtHeaders(url, headers);
          const reqBody = this._extractBody(optionsOrHeaders, body);
          const result = await sendMessage(
            "http_delete",
            JSON.stringify([null, this.reqcopyWith, url, headers, reqBody])
          );
          return JSON.parse(result);
        }
        async patch(url, optionsOrHeaders, body) {
          let headers = this._extractHeaders(optionsOrHeaders);
          headers = this._mergeExtHeaders(url, headers);
          const reqBody = this._extractBody(optionsOrHeaders, body);
          const result = await sendMessage(
            "http_patch",
            JSON.stringify([null, this.reqcopyWith, url, headers, reqBody])
          );
          return JSON.parse(result);
        }
      }
    ''');
  }

  static String _cleanUrl(String url) {
    try {
      var uri = Uri.parse(url);
      if (uri.hasQuery) {
        final cleanParams = <String, String>{};
        uri.queryParameters.forEach((key, value) {
          if (value.isNotEmpty) {
            cleanParams[key] = value;
          }
        });
        uri = uri.replace(
          queryParameters: cleanParams.isEmpty ? null : cleanParams,
        );
        return uri.toString();
      }
    } catch (_) {}
    return url;
  }

  static Map<String, String> _mergeHeaders(
    String url,
    Map<String, String> customHeaders,
  ) {
    final Map<String, String> merged = {
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Accept-Language': 'en-US,en;q=0.9',
      'Accept':
          'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8',
    };
    try {
      final uri = Uri.parse(url);
      final origin = '${uri.scheme}://${uri.host}';
      merged['Referer'] = '$origin/';
    } catch (_) {}
    customHeaders.forEach((key, value) {
      final existingKey = merged.keys.firstWhere(
        (k) => k.toLowerCase() == key.toLowerCase(),
        orElse: () => key,
      );
      merged[existingKey] = value;
    });
    return merged;
  }

  Future<String> _toHttpResponse(String method, List args) async {
    try {
      String url = args[2] as String;
      final customHeaders = args.length >= 4 && args[3] is Map
          ? Map<String, String>.from(args[3] as Map)
          : <String, String>{};

      url = _cleanUrl(url);
      final headers = _mergeHeaders(url, customHeaders);

      final body = args.length >= 5
          ? args[4] is List
                ? args[4] as List
                : args[4] is String
                ? args[4] as String
                : args[4] is Map
                ? jsonEncode(args[4])
                : args[4]?.toString()
          : null;

      final client = http.Client();
      final uri = Uri.parse(url);

      late http.Response response;

      switch (method) {
        case "HEAD":
          response = await client.head(uri, headers: headers);
          break;
        case "GET":
          response = await client.get(uri, headers: headers);
          break;
        case "POST":
          response = await client.post(uri, headers: headers, body: body);
          break;
        case "PUT":
          response = await client.put(uri, headers: headers, body: body);
          break;
        case "DELETE":
          response = await client.delete(uri, headers: headers, body: body);
          break;
        case "PATCH":
          response = await client.patch(uri, headers: headers, body: body);
          break;
        default:
          response = await client.get(uri, headers: headers);
      }

      String bodyString;
      try {
        bodyString = utf8.decode(response.bodyBytes, allowMalformed: true);
      } catch (_) {
        bodyString = response.body;
      }

      if (service != null) {
        service!.lastStatusCode = response.statusCode;
        service!.lastRequestUrl = url;
      }

      final resMap = {
        'body': bodyString,
        'headers': response.headers,
        'isRedirect': response.isRedirect,
        'persistentConnection': response.persistentConnection,
        'reasonPhrase': response.reasonPhrase,
        'statusCode': response.statusCode,
        'request': {
          'contentLength': response.request?.contentLength,
          'followRedirects': response.request?.followRedirects,
          'headers': response.request?.headers,
          'method': response.request?.method,
          'url': response.request?.url.toString(),
        },
      };

      return jsonEncode(resMap);
    } catch (e) {
      return jsonEncode({
        'statusCode': 500,
        'body': e.toString(),
        'headers': <String, String>{},
      });
    }
  }
}
