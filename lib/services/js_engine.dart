import 'dart:convert';
import 'dart:io';
import 'package:flutter_js/flutter_js.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as html_dom;
import 'package:shared_preferences/shared_preferences.dart';

class JsEngine {
  late JavascriptRuntime _runtime;
  final int sourceId;

  JsEngine(this.sourceId) {
    _runtime = getJavascriptRuntime();
    _setupConsole();
    _setupHttpClient();
    _setupSharedPreferences(sourceId);
    _setupDomParser();
    _setupStringPrototypes();
    _setupHelpers();
    _setupNativeSpeedups();
  }

  void _setupConsole() {
    _runtime.onMessage('log', (dynamic args) {
      print("[JS LOG]: ${args[0]}");
      return null;
    });

    _runtime.evaluate('''
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
    ''');
  }

  void _setupHttpClient() {
    _runtime.onMessage('http_get', (dynamic args) async {
      try {
        final url = args[0] as String;
        final headers = Map<String, String>.from(args[1] as Map? ?? {});
        final response = await http.get(Uri.parse(url), headers: headers);
        return json.encode({
          'statusCode': response.statusCode,
          'body': response.body,
        });
      } catch (e) {
        return json.encode({'statusCode': 500, 'body': e.toString()});
      }
    });

    _runtime.onMessage('http_post', (dynamic args) async {
      try {
        final url = args[0] as String;
        final headers = Map<String, String>.from(args[1] as Map? ?? {});
        final body = args[2];
        final response = await http.post(
          Uri.parse(url),
          headers: headers,
          body: body is Map ? json.encode(body) : body.toString(),
        );
        return json.encode({
          'statusCode': response.statusCode,
          'body': response.body,
        });
      } catch (e) {
        return json.encode({'statusCode': 500, 'body': e.toString()});
      }
    });

    _runtime.evaluate('''
      class Client {
        async get(url, headers) {
          const res = await sendMessage('http_get', JSON.stringify([url, headers || {}]));
          return JSON.parse(res);
        }
        async post(url, headers, body) {
          const res = await sendMessage('http_post', JSON.stringify([url, headers || {}, body || ""]));
          return JSON.parse(res);
        }
      }
    ''');
  }

  void _setupSharedPreferences(int sourceId) {
    _runtime.onMessage('save_pref', (dynamic args) async {
      try {
        final key = args[0] as String;
        final value = args[1];
        final sp = await SharedPreferences.getInstance();
        await sp.setString('ext_pref_${sourceId}_$key', json.encode(value));
      } catch (e) {
        print("Error saving preference: $e");
      }
      return null;
    });

    _runtime.evaluate('''
      class SharedPreferences {
        get(key) {
          if (typeof _userPrefs !== 'undefined' && _userPrefs[key] !== undefined && _userPrefs[key] !== null) {
            return _userPrefs[key];
          }
          if (typeof extension !== 'undefined' && typeof extension.getSourcePreferences === 'function') {
            try {
              const prefs = extension.getSourcePreferences() || [];
              const p = prefs.find(x => x.key === key);
              if (p) {
                if (p.listPreference) return p.listPreference.entryValues[p.listPreference.valueIndex || 0];
                if (p.checkBoxPreference) return p.checkBoxPreference.value;
                if (p.switchPreferenceCompat) return p.switchPreferenceCompat.value;
                if (p.editTextPreference) return p.editTextPreference.value;
                if (p.multiSelectListPreference) return p.multiSelectListPreference.values;
              }
            } catch(e) {
              console.log("Error getting default pref: " + e);
            }
          }
          return null;
        }
        getString(key, defaultValue) {
          const val = this.get(key);
          return val !== null ? val : defaultValue;
        }
        setString(key, value) {
          if (typeof _userPrefs === 'undefined') _userPrefs = {};
          _userPrefs[key] = value;
          sendMessage('save_pref', JSON.stringify([key, value]));
          return true;
        }
      }
    ''');
  }

  final Map<int, html_dom.Element?> _elements = {};
  int _elementKey = 0;

  void _setupDomParser() {
    _runtime.onMessage('get_doc_element', (dynamic args) {
      final html = args[0] as String;
      final type = args[1] as String;
      final doc = html_parser.parse(html);
      final element = type == 'body' ? doc.body : doc.documentElement;
      _elementKey++;
      _elements[_elementKey] = element;
      return _elementKey;
    });

    _runtime.onMessage('get_element_string', (dynamic args) {
      final type = args[0] as String;
      final key = args[1] as int;
      final element = _elements[key];
      if (element == null) return "";
      switch (type) {
        case 'text':
          return element.text;
        case 'outerHtml':
          return element.outerHtml;
        case 'innerHtml':
          return element.innerHtml;
        case 'getSrc':
          return element.attributes['src'] ?? "";
        case 'getHref':
          return element.attributes['href'] ?? "";
        case 'getImg':
          return element.attributes['src'] ??
              element.attributes['data-src'] ??
              "";
        default:
          return "";
      }
    });

    _runtime.onMessage('doc_select', (dynamic args) {
      final html = args[0] as String;
      final selector = args[1] as String;
      final doc = html_parser.parse(html);
      final elements = doc.querySelectorAll(selector);
      final List<int> keys = [];
      for (var ele in elements) {
        _elementKey++;
        _elements[_elementKey] = ele;
        keys.add(_elementKey);
      }
      return json.encode(keys);
    });

    _runtime.onMessage('ele_select', (dynamic args) {
      final key = args[0] as int;
      final selector = args[1] as String;
      final element = _elements[key];
      if (element == null) return json.encode([]);
      final elements = element.querySelectorAll(selector);
      final List<int> keys = [];
      for (var ele in elements) {
        _elementKey++;
        _elements[_elementKey] = ele;
        keys.add(_elementKey);
      }
      return json.encode(keys);
    });

    _runtime.onMessage('doc_select_first', (dynamic args) {
      final html = args[0] as String;
      final selector = args[1] as String;
      final doc = html_parser.parse(html);
      final ele = doc.querySelector(selector);
      _elementKey++;
      _elements[_elementKey] = ele;
      return _elementKey;
    });

    _runtime.onMessage('ele_selectFirst', (dynamic args) {
      final key = args[0] as int;
      final selector = args[1] as String;
      final element = _elements[key];
      if (element == null) return 0;
      final ele = element.querySelector(selector);
      _elementKey++;
      _elements[_elementKey] = ele;
      return _elementKey;
    });

    _runtime.onMessage('ele_attr', (dynamic args) {
      final key = args[0] as int;
      final attr = args[1] as String;
      final element = _elements[key];
      return element?.attributes[attr] ?? "";
    });

    _runtime.evaluate('''
      class Document {
        constructor(html) {
          this.html = html;
        }
        get body() {
          const key = sendMessage('get_doc_element', JSON.stringify([this.html, 'body']));
          return new Element(key);
        }
        select(selector) {
          const keysJson = sendMessage('doc_select', JSON.stringify([this.html, selector]));
          const keys = JSON.parse(keysJson);
          return keys.map(k => new Element(k));
        }
        selectFirst(selector) {
          const key = sendMessage('doc_select_first', JSON.stringify([this.html, selector]));
          return new Element(key);
        }
      }

      class Element {
        constructor(key) {
          this.key = key;
        }
        get text() {
          return sendMessage('get_element_string', JSON.stringify(['text', this.key]));
        }
        get outerHtml() {
          return sendMessage('get_element_string', JSON.stringify(['outerHtml', this.key]));
        }
        get innerHtml() {
          return sendMessage('get_element_string', JSON.stringify(['innerHtml', this.key]));
        }
        attr(name) {
          return sendMessage('ele_attr', JSON.stringify([this.key, name]));
        }
        select(selector) {
          const keysJson = sendMessage('ele_select', JSON.stringify([this.key, selector]));
          const keys = JSON.parse(keysJson);
          return keys.map(k => new Element(k));
        }
        selectFirst(selector) {
          const k = sendMessage('ele_selectFirst', JSON.stringify([this.key, selector]));
          return new Element(k);
        }
        getSrc() {
          return sendMessage('get_element_string', JSON.stringify(['getSrc', this.key]));
        }
        getImg() {
          return sendMessage('get_element_string', JSON.stringify(['getImg', this.key]));
        }
        getHref() {
          return sendMessage('get_element_string', JSON.stringify(['getHref', this.key]));
        }
      }

      function parseHtml(html) {
        return new Document(html);
      }
    ''');
  }

  void _setupStringPrototypes() {
    _runtime.evaluate('''
      String.prototype.substringAfter = function(pattern) {
        const index = this.indexOf(pattern);
        if (index === -1) return this;
        return this.substring(index + pattern.length);
      };

      String.prototype.substringBefore = function(pattern) {
        const index = this.indexOf(pattern);
        if (index === -1) return this;
        return this.substring(0, index);
      };

      String.prototype.substringBetween = function(left, right) {
        const start = this.indexOf(left);
        if (start === -1) return "";
        const end = this.indexOf(right, start + left.length);
        if (end === -1) return "";
        return this.substring(start + left.length, end);
      };
    ''');
  }

  void _setupHelpers() {
    _runtime.evaluate('''
      async function jsonStringify(promiseOrValue) {
        const resolved = await promiseOrValue;
        return JSON.stringify(resolved);
      }
    ''');
  }

  void _setupNativeSpeedups() {
    _runtime.onMessage('native_b64dec', (dynamic args) {
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

    _runtime.onMessage('native_inflate', (dynamic args) {
      try {
        final List<dynamic> list = args[0] as List;
        final bytes = list.map((e) => e as int).toList();
        final decompressed = gzip.decode(bytes);
        return json.encode(decompressed);
      } catch (_) {
        return '[]';
      }
    });
  }

  Future<void> loadExtension(
    String sourceCode,
    String baseUrl,
    Map<String, dynamic> prefs,
  ) async {
    final prefsJson = json.encode(prefs);
    _runtime.evaluate('var _userPrefs = $prefsJson;');
    _runtime.evaluate('''
      class MProvider {
        constructor() {
          this.source = {
            baseUrl: "$baseUrl"
          };
        }
      }
    ''');
    _runtime.evaluate(sourceCode);
    _runtime.evaluate(r'''
      if (typeof DefaultExtension !== 'undefined') {
        DefaultExtension.prototype.originalB64dec = DefaultExtension.prototype.b64dec;
        DefaultExtension.prototype.b64dec = function(str) {
          if (str && str.length > 100) {
            return JSON.parse(sendMessage('native_b64dec', JSON.stringify([str])));
          }
          return this.originalB64dec(str);
        };
        DefaultExtension.prototype.inflate = function(data) {
          return JSON.parse(sendMessage('native_inflate', JSON.stringify([data])));
        };
        if (typeof DefaultExtension.prototype.getDetail === 'function') {
          DefaultExtension.prototype.originalGetDetail = DefaultExtension.prototype.getDetail;
          DefaultExtension.prototype.getDetail = function(url) {
            if (url && typeof url === 'string' && url.includes('/')) {
              const lastSegment = url.split('/').filter(Boolean).pop();
              if (/^\d+$/.test(lastSegment)) {
                try {
                  return this.originalGetDetail(url);
                } catch (e) {
                  return this.originalGetDetail(lastSegment);
                }
              }
            }
            return this.originalGetDetail(url);
          };
        }
      }
      var extension = new DefaultExtension();
    ''');
  }

  Future<List<Map<String, dynamic>>> getPopular(int page) async {
    final res = _runtime.evaluate('jsonStringify(extension.getPopular($page))');
    final resolved = await _runtime.handlePromise(res);
    final data = json.decode(resolved.stringResult);
    return List<Map<String, dynamic>>.from(data['list']);
  }

  Future<List<Map<String, dynamic>>> search(String query, int page) async {
    final escapedQuery = query.replaceAll('"', '\\"');
    final res = _runtime.evaluate(
      'jsonStringify(extension.search("$escapedQuery", $page, []))',
    );
    final resolved = await _runtime.handlePromise(res);
    final data = json.decode(resolved.stringResult);
    return List<Map<String, dynamic>>.from(data['list']);
  }

  Future<Map<String, dynamic>> getDetail(String url) async {
    final escapedUrl = url.replaceAll('"', '\\"');
    final res = _runtime.evaluate(
      'jsonStringify(extension.getDetail("$escapedUrl"))',
    );
    final resolved = await _runtime.handlePromise(res);
    return json.decode(resolved.stringResult);
  }

  Future<List<dynamic>> getVideoList(String url) async {
    final escapedUrl = url.replaceAll('"', '\\"');
    final res = _runtime.evaluate(
      'jsonStringify(extension.getVideoList("$escapedUrl"))',
    );
    final resolved = await _runtime.handlePromise(res);
    return json.decode(resolved.stringResult);
  }

  Future<String?> fetchUrl(String url, Map<String, String> headers) async {
    try {
      final escapedUrl = url.replaceAll(r'\', r'\\').replaceAll('"', r'\"');
      final headersJson = json.encode(headers);
      final res = _runtime.evaluate(
        'jsonStringify(extension.client.get("$escapedUrl", $headersJson))',
      );
      final resolved = await _runtime.handlePromise(res);
      final data = json.decode(resolved.stringResult);
      if (data is Map && data['statusCode'] == 200) {
        return data['body'] as String?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<dynamic>> getSourcePreferences() async {
    try {
      final res = _runtime.evaluate(
        'jsonStringify(typeof extension !== "undefined" && typeof extension.getSourcePreferences === "function" ? extension.getSourcePreferences() : [])',
      );
      final resolved = await _runtime.handlePromise(res);
      final decoded = json.decode(resolved.stringResult);
      if (decoded is List) {
        return decoded;
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  void dispose() {
    _runtime.dispose();
  }
}
