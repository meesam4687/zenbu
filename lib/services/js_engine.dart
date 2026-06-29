import 'dart:convert';
import 'dart:io';
import 'package:flutter_js/flutter_js.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as html_dom;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenbu/services/crypto_utils.dart';
import 'package:zenbu/models/extensions_models.dart';
import 'package:flutter/foundation.dart';
import 'package:pseudom/pseudom.dart' as pseudom;
import 'package:xpath_selector_html_parser/xpath_selector_html_parser.dart';

class JsEngine {
  late JavascriptRuntime _runtime;
  final int sourceId;
  int? lastStatusCode;
  String? lastRequestUrl;

  JsEngine(this.sourceId) {
    _runtime = getJavascriptRuntime();
    _setupConsole();
    _setupHttpClient();
    _setupSharedPreferences(sourceId);
    _setupDomParser();
    _setupStringPrototypes();
    _setupHelpers();
    _setupNativeSpeedups();
    _setupCryptoBindings();
  }

  void _setupConsole() {
    _runtime.onMessage('log', (dynamic args) {
      debugPrint("[JS LOG]: ${args[0]}");
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
        String url;
        Map<String, String> headers;
        if (args is List &&
            args.isNotEmpty &&
            args[0] == null &&
            args.length >= 4) {
          url = args[2] as String;
          headers = Map<String, String>.from(args[3] as Map? ?? {});
        } else {
          url = args[0] as String;
          headers = Map<String, String>.from(args[1] as Map? ?? {});
        }

        url = _cleanUrl(url);
        lastRequestUrl = url;
        final response = await http.get(
          Uri.parse(url),
          headers: _mergeHeaders(url, headers),
        );
        lastStatusCode = response.statusCode;

        String bodyString;
        try {
          bodyString = utf8.decode(response.bodyBytes, allowMalformed: true);
        } catch (_) {
          bodyString = response.body;
        }

        if (bodyString.contains("Just a moment...") ||
            bodyString.contains("cloudflare") ||
            response.statusCode == 403 ||
            response.statusCode == 503) {}

        return json.encode({
          'statusCode': response.statusCode,
          'headers': response.headers,
          'body': bodyString,
        });
      } catch (e) {
        return json.encode({
          'statusCode': 500,
          'headers': <String, String>{},
          'body': e.toString(),
        });
      }
    });

    _runtime.onMessage('http_post', (dynamic args) async {
      try {
        String url;
        Map<String, String> headers;
        dynamic body;
        if (args is List &&
            args.isNotEmpty &&
            args[0] == null &&
            args.length >= 4) {
          url = args[2] as String;
          headers = Map<String, String>.from(args[3] as Map? ?? {});
          body = args.length >= 5 ? args[4] : null;
        } else {
          url = args[0] as String;
          headers = Map<String, String>.from(args[1] as Map? ?? {});
          body = args.length >= 3 ? args[2] : null;
        }

        lastRequestUrl = url;
        final response = await http.post(
          Uri.parse(url),
          headers: _mergeHeaders(url, headers),
          body: body is Map ? json.encode(body) : body?.toString() ?? "",
        );
        lastStatusCode = response.statusCode;
        String bodyString;
        try {
          bodyString = utf8.decode(response.bodyBytes, allowMalformed: true);
        } catch (_) {
          bodyString = response.body;
        }
        return json.encode({
          'statusCode': response.statusCode,
          'headers': response.headers,
          'body': bodyString,
        });
      } catch (e) {
        return json.encode({
          'statusCode': 500,
          'headers': <String, String>{},
          'body': e.toString(),
        });
      }
    });

    _runtime.onMessage('http_head', (dynamic args) async {
      try {
        String url;
        Map<String, String> headers;
        if (args is List &&
            args.isNotEmpty &&
            args[0] == null &&
            args.length >= 4) {
          url = args[2] as String;
          headers = Map<String, String>.from(args[3] as Map? ?? {});
        } else {
          url = args[0] as String;
          headers = Map<String, String>.from(args[1] as Map? ?? {});
        }

        lastRequestUrl = url;
        final response = await http.head(
          Uri.parse(url),
          headers: _mergeHeaders(url, headers),
        );
        String bodyString;
        try {
          bodyString = utf8.decode(response.bodyBytes, allowMalformed: true);
        } catch (_) {
          bodyString = response.body;
        }
        return json.encode({
          'statusCode': response.statusCode,
          'headers': response.headers,
          'body': bodyString,
        });
      } catch (e) {
        return json.encode({
          'statusCode': 500,
          'headers': <String, String>{},
          'body': e.toString(),
        });
      }
    });

    _runtime.onMessage('http_put', (dynamic args) async {
      try {
        String url;
        Map<String, String> headers;
        dynamic body;
        if (args is List &&
            args.isNotEmpty &&
            args[0] == null &&
            args.length >= 4) {
          url = args[2] as String;
          headers = Map<String, String>.from(args[3] as Map? ?? {});
          body = args.length >= 5 ? args[4] : null;
        } else {
          url = args[0] as String;
          headers = Map<String, String>.from(args[1] as Map? ?? {});
          body = args.length >= 3 ? args[2] : null;
        }

        lastRequestUrl = url;
        final response = await http.put(
          Uri.parse(url),
          headers: _mergeHeaders(url, headers),
          body: body is Map ? json.encode(body) : body?.toString() ?? "",
        );
        String bodyString;
        try {
          bodyString = utf8.decode(response.bodyBytes, allowMalformed: true);
        } catch (_) {
          bodyString = response.body;
        }
        return json.encode({
          'statusCode': response.statusCode,
          'headers': response.headers,
          'body': bodyString,
        });
      } catch (e) {
        return json.encode({
          'statusCode': 500,
          'headers': <String, String>{},
          'body': e.toString(),
        });
      }
    });

    _runtime.onMessage('http_delete', (dynamic args) async {
      try {
        String url;
        Map<String, String> headers;
        dynamic body;
        if (args is List &&
            args.isNotEmpty &&
            args[0] == null &&
            args.length >= 4) {
          url = args[2] as String;
          headers = Map<String, String>.from(args[3] as Map? ?? {});
          body = args.length >= 5 ? args[4] : null;
        } else {
          url = args[0] as String;
          headers = Map<String, String>.from(args[1] as Map? ?? {});
          body = args.length >= 3 ? args[2] : null;
        }

        lastRequestUrl = url;
        final response = await http.delete(
          Uri.parse(url),
          headers: _mergeHeaders(url, headers),
          body: body is Map ? json.encode(body) : body?.toString(),
        );
        String bodyString;
        try {
          bodyString = utf8.decode(response.bodyBytes, allowMalformed: true);
        } catch (_) {
          bodyString = response.body;
        }
        return json.encode({
          'statusCode': response.statusCode,
          'headers': response.headers,
          'body': bodyString,
        });
      } catch (e) {
        return json.encode({
          'statusCode': 500,
          'headers': <String, String>{},
          'body': e.toString(),
        });
      }
    });

    _runtime.onMessage('http_patch', (dynamic args) async {
      try {
        String url;
        Map<String, String> headers;
        dynamic body;
        if (args is List &&
            args.isNotEmpty &&
            args[0] == null &&
            args.length >= 4) {
          url = args[2] as String;
          headers = Map<String, String>.from(args[3] as Map? ?? {});
          body = args.length >= 5 ? args[4] : null;
        } else {
          url = args[0] as String;
          headers = Map<String, String>.from(args[1] as Map? ?? {});
          body = args.length >= 3 ? args[2] : null;
        }

        lastRequestUrl = url;
        final response = await http.patch(
          Uri.parse(url),
          headers: _mergeHeaders(url, headers),
          body: body is Map ? json.encode(body) : body?.toString() ?? "",
        );
        String bodyString;
        try {
          bodyString = utf8.decode(response.bodyBytes, allowMalformed: true);
        } catch (_) {
          bodyString = response.body;
        }
        return json.encode({
          'statusCode': response.statusCode,
          'headers': response.headers,
          'body': bodyString,
        });
      } catch (e) {
        return json.encode({
          'statusCode': 500,
          'headers': <String, String>{},
          'body': e.toString(),
        });
      }
    });

    _runtime.evaluate('''
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
        async get(url, optionsOrHeaders) {
          let headers = this._extractHeaders(optionsOrHeaders);
          headers = this._mergeExtHeaders(url, headers);
          const res = await sendMessage('http_get', JSON.stringify([null, this.reqcopyWith, url, headers]));
          return JSON.parse(res);
        }
        async post(url, optionsOrHeaders, body) {
          let headers = this._extractHeaders(optionsOrHeaders);
          headers = this._mergeExtHeaders(url, headers);
          const reqBody = this._extractBody(optionsOrHeaders, body);
          const res = await sendMessage('http_post', JSON.stringify([null, this.reqcopyWith, url, headers, reqBody]));
          return JSON.parse(res);
        }
        async head(url, optionsOrHeaders) {
          let headers = this._extractHeaders(optionsOrHeaders);
          headers = this._mergeExtHeaders(url, headers);
          const res = await sendMessage('http_head', JSON.stringify([null, this.reqcopyWith, url, headers]));
          return JSON.parse(res);
        }
        async put(url, optionsOrHeaders, body) {
          let headers = this._extractHeaders(optionsOrHeaders);
          headers = this._mergeExtHeaders(url, headers);
          const reqBody = this._extractBody(optionsOrHeaders, body);
          const res = await sendMessage('http_put', JSON.stringify([null, this.reqcopyWith, url, headers, reqBody]));
          return JSON.parse(res);
        }
        async delete(url, optionsOrHeaders, body) {
          let headers = this._extractHeaders(optionsOrHeaders);
          headers = this._mergeExtHeaders(url, headers);
          const reqBody = this._extractBody(optionsOrHeaders, body);
          const res = await sendMessage('http_delete', JSON.stringify([null, this.reqcopyWith, url, headers, reqBody]));
          return JSON.parse(res);
        }
        async patch(url, optionsOrHeaders, body) {
          let headers = this._extractHeaders(optionsOrHeaders);
          headers = this._mergeExtHeaders(url, headers);
          const reqBody = this._extractBody(optionsOrHeaders, body);
          const res = await sendMessage('http_patch', JSON.stringify([null, this.reqcopyWith, url, headers, reqBody]));
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
      } catch (_) {}
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
        getBool(key, defaultValue) {
          const val = this.get(key);
          return val !== null ? (val === true || val === 'true') : defaultValue;
        }
        setBool(key, value) {
          return this.setString(key, value);
        }
        getInt(key, defaultValue) {
          const val = this.get(key);
          if (val !== null) {
            const parsed = parseInt(val);
            return isNaN(parsed) ? defaultValue : parsed;
          }
          return defaultValue;
        }
        setInt(key, value) {
          return this.setString(key, value);
        }
        getDouble(key, defaultValue) {
          const val = this.get(key);
          if (val !== null) {
            const parsed = parseFloat(val);
            return isNaN(parsed) ? defaultValue : parsed;
          }
          return defaultValue;
        }
        setDouble(key, value) {
          return this.setString(key, value);
        }
      }
    ''');
  }

  final Map<int, html_dom.Element?> _elements = {};
  int _elementKey = 0;
  final Map<int, html_dom.Document> _documents = {};
  int _documentKey = 0;

  int _asInt(dynamic val) {
    if (val is int) return val;
    if (val is num) return val.toInt();
    if (val != null) {
      return int.tryParse(val.toString()) ?? 0;
    }
    return 0;
  }

  void _clearCache() {
    _elements.clear();
    _elementKey = 0;
    _documents.clear();
    _documentKey = 0;
  }

  void _setupDomParser() {
    _runtime.onMessage('parse_html', (dynamic args) {
      final html = args[0] as String;
      final doc = html_parser.parse(html);
      _documentKey++;
      _documents[_documentKey] = doc;
      return _documentKey;
    });

    _runtime.onMessage('get_doc_element', (dynamic args) {
      final docKey = _asInt(args[0]);
      final type = args[1] as String;
      final doc = _documents[docKey];
      final element = doc == null
          ? null
          : switch (type) {
            'body' => doc.body,
            'documentElement' => doc.documentElement,
            'head' => doc.head,
            _ => doc.parent,
          };
      _elementKey++;
      _elements[_elementKey] = element;
      return _elementKey;
    });

    _runtime.onMessage('get_doc_string', (dynamic args) {
      final docKey = _asInt(args[0]);
      final type = args[1] as String;
      final doc = _documents[docKey];
      if (doc == null) return "";
      final res = switch (type) {
        'text' => doc.text,
        _ => doc.outerHtml,
      };
      return res;
    });

    _runtime.onMessage('get_element_string', (dynamic args) {
      final type = args[0] as String;
      final key = _asInt(args[1]);
      final element = _elements[key];
      if (element == null) return "";
      final res = switch (type) {
        'text' => element.text,
        'innerHtml' => element.innerHtml,
        'outerHtml' => element.outerHtml,
        'className' => element.className,
        'localName' => element.localName,
        'namespaceUri' => element.namespaceUri,
        'getSrc' =>
          element.attributes['src'] ?? _regSrcMatcher(element.outerHtml),
        'getImg' =>
          element.attributes['img'] ??
              element.attributes['src'] ??
              _regImgMatcher(element.outerHtml),
        'getHref' =>
          element.attributes['href'] ?? _regHrefMatcher(element.outerHtml),
        'getDataSrc' =>
          element.attributes['data-src'] ??
              _regDataSrcMatcher(element.outerHtml),
        _ => "",
      };
      return res;
    });

    _runtime.onMessage('doc_select_first', (dynamic args) {
      final docKey = _asInt(args[0]);
      final selector = args[1] as String;
      final doc = _documents[docKey];
      _elementKey++;
      _elements[_elementKey] =
          doc == null ? null : _docSelectFirst(doc, selector);
      return _elementKey;
    });

    _runtime.onMessage('ele_selectFirst', (dynamic args) {
      final dynamic first = args[0];
      final dynamic second = args[1];
      String selector;
      int key;
      if (first is int || first is num || (first != null && int.tryParse(first.toString()) != null)) {
        key = _asInt(first);
        selector = second as String;
      } else {
        selector = first as String;
        key = _asInt(second);
      }
      final element = _elements[key];
      _elementKey++;
      _elements[_elementKey] = element == null
          ? null
          : _selectFirst(element, selector);
      return _elementKey;
    });

    _runtime.onMessage('ele_element_sibling', (dynamic args) {
      final type = args[0] as String;
      final key = _asInt(args[1]);
      final ele = _elements[key];
      final element = type == 'nextElementSibling'
          ? ele?.nextElementSibling
          : ele?.previousElementSibling;
      _elementKey++;
      _elements[_elementKey] = element;
      return _elementKey;
    });

    _runtime.onMessage('ele_attr', (dynamic args) {
      final dynamic first = args[0];
      final dynamic second = args[1];
      String attrName;
      int key;
      if (first is int || first is num || (first != null && int.tryParse(first.toString()) != null)) {
        key = _asInt(first);
        attrName = second as String;
      } else {
        attrName = first as String;
        key = _asInt(second);
      }
      return _elements[key]?.attributes[attrName] ?? "";
    });

    _runtime.onMessage('doc_attr', (dynamic args) {
      final docKey = _asInt(args[0]);
      final attr = args[1] as String;
      final doc = _documents[docKey];
      return doc?.attributes[attr] ?? "";
    });

    _runtime.onMessage('ele_has_attr', (dynamic args) {
      final dynamic first = args[0];
      final dynamic second = args[1];
      String attr;
      int key;
      if (first is int || first is num || (first != null && int.tryParse(first.toString()) != null)) {
        key = _asInt(first);
        attr = second as String;
      } else {
        attr = first as String;
        key = _asInt(second);
      }
      return _elements[key]?.attributes.containsKey(attr) ?? false;
    });

    _runtime.onMessage('doc_has_attr', (dynamic args) {
      final docKey = _asInt(args[0]);
      final attr = args[1] as String;
      final doc = _documents[docKey];
      return doc?.attributes.containsKey(attr) ?? false;
    });

    _runtime.onMessage('doc_xpath_first', (dynamic args) {
      final docKey = _asInt(args[0]);
      final xpath = args[1] as String;
      final doc = _documents[docKey];
      return doc == null ? "" : _docXpathFirst(doc, xpath);
    });

    _runtime.onMessage('ele_xpathFirst', (dynamic args) {
      final dynamic first = args[0];
      final dynamic second = args[1];
      String xpath;
      int key;
      if (first is int || first is num || (first != null && int.tryParse(first.toString()) != null)) {
        key = _asInt(first);
        xpath = second as String;
      } else {
        xpath = first as String;
        key = _asInt(second);
      }
      final element = _elements[key];
      return element == null ? "" : _eleXpathFirst(element, xpath);
    });

    _runtime.onMessage('xpathFirst', (dynamic args) {
      final xpath = args[0] as String;
      final key = _asInt(args[1]);
      final element = _elements[key];
      return element == null ? "" : _eleXpathFirst(element, xpath);
    });

    _runtime.onMessage('doc_xpath', (dynamic args) {
      final docKey = _asInt(args[0]);
      final xpath = args[1] as String;
      final doc = _documents[docKey];
      return json.encode(doc == null ? <String>[] : _docXpath(doc, xpath));
    });

    _runtime.onMessage('ele_xpath', (dynamic args) {
      final dynamic first = args[0];
      final dynamic second = args[1];
      String xpath;
      int key;
      if (first is int || first is num || (first != null && int.tryParse(first.toString()) != null)) {
        key = _asInt(first);
        xpath = second as String;
      } else {
        xpath = first as String;
        key = _asInt(second);
      }
      final element = _elements[key];
      return json.encode(
        element == null ? <String>[] : _eleXpath(element, xpath),
      );
    });

    _runtime.onMessage('xpath', (dynamic args) {
      final xpath = args[0] as String;
      final key = _asInt(args[1]);
      final element = _elements[key];
      return json.encode(
        element == null ? <String>[] : _eleXpath(element, xpath),
      );
    });

    _runtime.onMessage('doc_get_elements_by', (dynamic args) {
      final docKey = _asInt(args[0]);
      final type = args[1] as String;
      final name = args[2] as String;
      final doc = _documents[docKey];
      if (doc == null) return json.encode(<int>[]);
      final elements = switch (type) {
        'children' => doc.children,
        'getElementsByTagName' => doc.getElementsByTagName(name),
        _ => doc.getElementsByClassName(name),
      };
      final List<int> elementKeys = [];
      for (var element in elements) {
        _elementKey++;
        _elements[_elementKey] = element;
        elementKeys.add(_elementKey);
      }
      return json.encode(elementKeys);
    });

    _runtime.onMessage('ele_get_elements_by', (dynamic args) {
      final type = args[0] as String;
      final name = args[1] as String;
      final key = _asInt(args[2]);
      final element = _elements[key];
      if (element == null) return json.encode(<int>[]);
      final elements = switch (type) {
        'children' => element.children,
        'getElementsByTagName' => element.getElementsByTagName(name),
        _ => element.getElementsByClassName(name),
      };
      final List<int> elementKeys = [];
      for (var ele in elements) {
        _elementKey++;
        _elements[_elementKey] = ele;
        elementKeys.add(_elementKey);
      }
      return json.encode(elementKeys);
    });

    _runtime.onMessage('doc_get_element_by_id', (dynamic args) {
      final docKey = _asInt(args[0]);
      final id = args[1] as String;
      final doc = _documents[docKey];
      _elementKey++;
      _elements[_elementKey] = doc?.getElementById(id);
      return _elementKey;
    });

    _runtime.onMessage('doc_select', (dynamic args) {
      final docKey = _asInt(args[0]);
      final selector = args[1] as String;
      final doc = _documents[docKey];
      if (doc == null) return json.encode(<int>[]);
      final elements = _docSelect(doc, selector);
      final List<int> elementKeys = [];
      for (var element in elements) {
        _elementKey++;
        _elements[_elementKey] = element;
        elementKeys.add(_elementKey);
      }
      return json.encode(elementKeys);
    });

    _runtime.onMessage('ele_select', (dynamic args) {
      final dynamic first = args[0];
      final dynamic second = args[1];
      String selector;
      int key;
      if (first is int || first is num || (first != null && int.tryParse(first.toString()) != null)) {
        key = _asInt(first);
        selector = second as String;
      } else {
        selector = first as String;
        key = _asInt(second);
      }
      final element = _elements[key];
      if (element == null) return json.encode(<int>[]);
      final elements = _select(element, selector);
      final List<int> elementKeys = [];
      for (var ele in elements) {
        _elementKey++;
        _elements[_elementKey] = ele;
        elementKeys.add(_elementKey);
      }
      return json.encode(elementKeys);
    });

    _runtime.evaluate('''
      class Document {
        constructor(htmlOrKey) {
          if (typeof htmlOrKey === 'string') {
            this.key = sendMessage('parse_html', JSON.stringify([htmlOrKey]));
          } else {
            this.key = htmlOrKey;
          }
        }
        getElement(type) {
          const key = sendMessage('get_doc_element', JSON.stringify([this.key, type]));
          return new Element(key);
        }
        get body() {
          return this.getElement('body');
        }
        get documentElement() {
          return this.getElement('documentElement');
        }
        get head() {
          return this.getElement('head');
        }
        get parent() {
          return this.getElement('parent');
        }
        getString(type) {
          return sendMessage('get_doc_string', JSON.stringify([this.key, type]));
        }
        get text() {
          return this.getString('text');
        }
        get outerHtml() {
          return this.getString('outerHtml');
        }
        selectFirst(selector) {
          const key = sendMessage('doc_select_first', JSON.stringify([this.key, selector]));
          return new Element(key);
        }
        select(selector) {
          let elements = [];
          JSON.parse(
            sendMessage("doc_select", JSON.stringify([this.key, selector]))
          ).forEach((key) => {
            elements.push(new Element(key));
          });
          return elements;
        }
        xpathFirst(xpath) {
          return sendMessage('doc_xpath_first', JSON.stringify([this.key, xpath]));
        }
        xpath(xpath) {
          return JSON.parse(sendMessage('doc_xpath', JSON.stringify([this.key, xpath])));
        }
        getElementsListBy(type, name) {
          name = name || '';
          let elements = [];
          JSON.parse(
            sendMessage("doc_get_elements_by", JSON.stringify([this.key, type, name]))
          ).forEach((key) => {
            elements.push(new Element(key));
          });
          return elements;
        }
        get children() {
          return this.getElementsListBy('children');
        }
        getElementsByTagName(name) {
          return this.getElementsListBy('getElementsByTagName', name);
        }
        getElementsByClassName(name) {
          return this.getElementsListBy('getElementsByClassName', name);
        }
        getElementById(id) {
          const key = sendMessage('doc_get_element_by_id', JSON.stringify([this.key, id]));
          return new Element(key);
        }
        attr(attr) {
          return sendMessage('doc_attr', JSON.stringify([this.key, attr]));
        }
        hasAttr(attr) {
          return sendMessage('doc_has_attr', JSON.stringify([this.key, attr]));
        }
      }

      class Element {
        constructor(key) {
          this.key = key;
        }
        getString(type) {
          return sendMessage('get_element_string', JSON.stringify([type, this.key]));
        }
        get text() {
          return this.getString('text');
        }
        get outerHtml() {
          return this.getString('outerHtml');
        }
        get innerHtml() {
          return this.getString('innerHtml');
        }
        get className() {
          return this.getString('className');
        }
        get localName() {
          return this.getString('localName');
        }
        get namespaceUri() {
          return this.getString('namespaceUri');
        }
        get getSrc() {
          return this.getString('getSrc');
        }
        get getImg() {
          return this.getString('getImg');
        }
        get getHref() {
          return this.getString('getHref');
        }
        get getDataSrc() {
          return this.getString('getDataSrc');
        }
        getElementSibling(type) {
          const key = sendMessage('ele_element_sibling', JSON.stringify([type, this.key]));
          return new Element(key);
        }
        get previousElementSibling() {
          return this.getElementSibling('previousElementSibling');
        }
        get nextElementSibling() {
          return this.getElementSibling('nextElementSibling');
        }
        getElementsListBy(type, name) {
          name = name || '';
          let elements = [];
          JSON.parse(
            sendMessage("ele_get_elements_by", JSON.stringify([type, name, this.key]))
          ).forEach((key) => {
            elements.push(new Element(key));
          });
          return elements;
        }
        get children() {
          return this.getElementsListBy('children');
        }
        getElementsByTagName(name) {
          return this.getElementsListBy('getElementsByTagName', name);
        }
        getElementsByClassName(name) {
          return this.getElementsListBy('getElementsByClassName', name);
        }
        xpath(xpath) {
          return JSON.parse(sendMessage('xpath', JSON.stringify([xpath, this.key])));
        }
        attr(attr) {
          return sendMessage('ele_attr', JSON.stringify([attr, this.key]));
        }
        xpathFirst(xpath) {
          return sendMessage('xpathFirst', JSON.stringify([xpath, this.key]));
        }
        selectFirst(selector) {
          const key = sendMessage('ele_selectFirst', JSON.stringify([selector, this.key]));
          return new Element(key);
        }
        select(selector) {
          let elements = [];
          JSON.parse(
            sendMessage("ele_select", JSON.stringify([selector, this.key]))
          ).forEach((key) => {
            elements.push(new Element(key));
          });
          return elements;
        }
        hasAttr(attr) {
          return sendMessage('ele_has_attr', JSON.stringify([attr, this.key]));
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
    ''');
  }

  void _setupHelpers() {
    _runtime.evaluate(r'''
      async function jsonStringify(promiseOrValue) {
        const resolved = await promiseOrValue;
        return JSON.stringify(resolved);
      }

      function unpackJs(code) {
        if (!code || !code.includes("p,a,c,k,e,")) return code;
        try {
          let packed = code.trim();
          if (packed.startsWith("eval(")) {
            packed = packed.substring(5);
            if (packed.endsWith(")")) {
              packed = packed.substring(0, packed.length - 1);
            }
            if (packed.endsWith(";")) {
              packed = packed.substring(0, packed.length - 1);
            }
          }
          const unpacker = new Function("return " + packed);
          return unpacker();
        } catch (e) {
          console.log("Unpacker error: " + e);
          return code;
        }
      }

      function unpackJsAndCombine(code) {
        if (!code) return "";
        const regex = /eval\s*\(\s*function\s*\(\s*p\s*,\s*a\s*,\s*c\s*,\s*k\s*,\s*e\s*,\s*[dr\s,]*\)[\s\S]+?\)/g;
        return code.replace(regex, (match) => {
          try {
            return unpackJs(match);
          } catch (e) {
            return match;
          }
        });
      }

      function deobfuscateJsPassword(password) {
        try {
          return eval(password);
        } catch (e) {
          return password;
        }
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
    ExtSource source,
    Map<String, dynamic> prefs,
  ) async {
    final prefsJson = json.encode(prefs);
    final sourceJson = json.encode(source.toJson());
    _runtime.evaluate('var _userPrefs = $prefsJson;');
    _runtime.evaluate('''
      class MProvider {
        get source() {
          return $sourceJson;
        }
        get supportsLatest() {
          return false;
        }
        getHeaders(url) {
          return {};
        }
        async getPopular(page) {
          throw new Error("getPopular not implemented");
        }
        async getLatestUpdates(page) {
          throw new Error("getLatestUpdates not implemented");
        }
        async search(query, page, filters) {
          throw new Error("search not implemented");
        }
        async getDetail(url) {
          throw new Error("getDetail not implemented");
        }
        async getPageList() {
          throw new Error("getPageList not implemented");
        }
        async getVideoList(url) {
          throw new Error("getVideoList not implemented");
        }
        async getHtmlContent(name, url) {
          throw new Error("getHtmlContent not implemented");
        }
        async cleanHtmlContent(html) {
          return html;
        }
        getFilterList() {
          return [];
        }
        getSourcePreferences() {
          return [];
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
    _clearCache();
    final res = _runtime.evaluate('jsonStringify(extension.getPopular($page))');
    final resolved = await _runtime.handlePromise(res);
    final data = json.decode(resolved.stringResult);
    return List<Map<String, dynamic>>.from(data['list']);
  }

  Future<List<Map<String, dynamic>>> search(String query, int page) async {
    _clearCache();
    final escapedQuery = query.replaceAll('"', '\\"');
    final res = _runtime.evaluate(
      'jsonStringify(extension.search("$escapedQuery", $page, typeof extension.getFilterList === "function" ? (function() { try { return extension.getFilterList() || []; } catch(e) { return []; } })() : []))',
    );
    final resolved = await _runtime.handlePromise(res);
    final data = json.decode(resolved.stringResult);

    return List<Map<String, dynamic>>.from(data['list']);
  }

  Future<Map<String, dynamic>> getDetail(String url) async {
    _clearCache();
    final escapedUrl = url.replaceAll('"', '\\"');
    final res = _runtime.evaluate(
      'jsonStringify(extension.getDetail("$escapedUrl"))',
    );
    final resolved = await _runtime.handlePromise(res);
    return json.decode(resolved.stringResult);
  }

  Future<List<dynamic>> getVideoList(String url) async {
    _clearCache();
    final escapedUrl = url.replaceAll('"', '\\"');
    final res = _runtime.evaluate(
      'jsonStringify(extension.getVideoList("$escapedUrl"))',
    );
    final resolved = await _runtime.handlePromise(res);
    return json.decode(resolved.stringResult);
  }

  Future<List<dynamic>> getPageList(String url) async {
    _clearCache();
    final escapedUrl = url.replaceAll('"', '\\"');
    final res = _runtime.evaluate(
      'jsonStringify(extension.getPageList("$escapedUrl"))',
    );
    final resolved = await _runtime.handlePromise(res);
    return json.decode(resolved.stringResult);
  }

  Future<Map<String, String>> getHeaders(String url) async {
    try {
      final escapedUrl = url.replaceAll(r'\', r'\\').replaceAll('"', r'\"');
      final res = _runtime.evaluate(
        'jsonStringify(extension.getHeaders("$escapedUrl"))',
      );
      final resolved = await _runtime.handlePromise(res);
      final decoded = json.decode(resolved.stringResult);
      if (decoded is Map) {
        return Map<String, String>.from(
          decoded.map((k, v) => MapEntry(k.toString(), v.toString())),
        );
      }
    } catch (_) {}
    return {};
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

  void _setupCryptoBindings() {
    _runtime.onMessage('cryptoHandler', (dynamic args) {
      final text = args[0] as String;
      final iv = args[1] as String;
      final key = args[2] as String;
      final isEncrypt = args[3] as bool;
      return CryptoAES.cryptoHandler(text, iv, key, isEncrypt);
    });

    _runtime.onMessage('encryptAESCryptoJS', (dynamic args) {
      final text = args[0] as String;
      final passphrase = args[1] as String;
      return CryptoAES.encryptAESCryptoJS(text, passphrase);
    });

    _runtime.onMessage('decryptAESCryptoJS', (dynamic args) {
      final encrypted = args[0] as String;
      final passphrase = args[1] as String;
      return CryptoAES.decryptAESCryptoJS(encrypted, passphrase);
    });

    _runtime.evaluate('''
      function cryptoHandler(text, iv, key, encrypt) {
        return sendMessage('cryptoHandler', JSON.stringify([text, iv, key, encrypt]));
      }

      function encryptAESCryptoJS(plainText, passphrase) {
        return sendMessage('encryptAESCryptoJS', JSON.stringify([plainText, passphrase]));
      }

      function decryptAESCryptoJS(encrypted, passphrase) {
        return sendMessage('decryptAESCryptoJS', JSON.stringify([encrypted, passphrase]));
      }
    ''');
  }

  void dispose() {
    _runtime.dispose();
  }

  String _cleanUrl(String url) {
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

  Map<String, String> _mergeHeaders(
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
}

bool _pseudoSelectorInitialized = false;

(int, int) _parseNth(String arg) {
  var working = arg.toLowerCase().replaceAll(' ', '');
  if (working == 'odd') return (2, 1);
  if (working == 'even') return (2, 0);
  final reg = RegExp(r'^(\d*)n([+-]?\d+)?$');
  final match = reg.firstMatch(working);
  if (match != null) {
    final aStr = match.group(1);
    final a = aStr == null || aStr.isEmpty ? 1 : int.parse(aStr);
    final bStr = match.group(2);
    final b = bStr == null ? 0 : int.parse(bStr);
    return (a, b);
  }
  final n = int.tryParse(working);
  if (n != null) return (0, n);
  return (0, 0);
}

bool _matchesNth(int index, int a, int b) {
  if (a == 0) return index == b;
  final diff = index - b;
  return diff % a == 0 && diff ~/ a >= 0;
}

String _getWholeText(html_dom.Element element) {
  return element.nodes.map((node) {
    if (node is html_dom.Text) return node.text;
    if (node is html_dom.Element) return _getWholeText(node);
    return '';
  }).join();
}

String _getWholeOwnText(html_dom.Element element) {
  return element.nodes.whereType<html_dom.Text>().map((t) => t.text).join();
}

bool _nthChild(html_dom.Element element, String? args) {
  if (args == null) return false;
  final parent = element.parent;
  if (parent == null) return false;
  final siblings = parent.children;
  final index = siblings.indexOf(element) + 1;
  final (a, b) = _parseNth(args);
  return _matchesNth(index, a, b);
}

bool _nthLastChild(html_dom.Element element, String? args) {
  if (args == null) return false;
  final parent = element.parent;
  if (parent == null) return false;
  final siblings = parent.children;
  final index = siblings.length - siblings.indexOf(element);
  final (a, b) = _parseNth(args);
  return _matchesNth(index, a, b);
}

bool _nthOfType(html_dom.Element element, String? args) {
  if (args == null) return false;
  final parent = element.parent;
  if (parent == null) return false;
  final siblings = parent.children
      .where((e) => e.localName == element.localName)
      .toList();
  final index = siblings.indexOf(element) + 1;
  final (a, b) = _parseNth(args);
  return _matchesNth(index, a, b);
}

bool _nthLastOfType(html_dom.Element element, String? args) {
  if (args == null) return false;
  final parent = element.parent;
  if (parent == null) return false;
  final siblings = parent.children
      .where((e) => e.localName == element.localName)
      .toList();
  final index = siblings.length - siblings.indexOf(element);
  final (a, b) = _parseNth(args);
  return _matchesNth(index, a, b);
}

bool _has(html_dom.Element element, String? args) {
  if (args == null) return false;
  final parent = element.parent;
  final res = parent == null
      ? false
      : pseudom.parse(args.replaceAll(':not', ':inot')).selectFirst(parent) ==
            element;
  return res
      ? res
      : pseudom.parse(args.replaceAll(':not', ':inot')).selectFirst(element) !=
            null;
}

bool _inot(html_dom.Element element, String? args) {
  if (args == null) return false;
  final parent = element.parent;
  final res = parent == null
      ? false
      : pseudom.parse(args.replaceAll(':not', ':inot')).selectFirst(parent) !=
            element;
  return res
      ? res
      : pseudom.parse(args.replaceAll(':not', ':inot')).selectFirst(element) ==
            null;
}

bool _contains(html_dom.Element element, String? args) {
  final text = args ?? '';
  return element.text.toLowerCase().contains(text.toLowerCase());
}

bool _containsOwn(html_dom.Element element, String? args) {
  final text = args ?? '';
  final ownText = element.nodes
      .whereType<html_dom.Text>()
      .map((t) => t.text)
      .join();
  return ownText.toLowerCase().contains(text.toLowerCase());
}

bool _matches(html_dom.Element element, String? args) {
  if (args == null) return false;
  try {
    final reg = RegExp(args, caseSensitive: false);
    return reg.hasMatch(element.text);
  } catch (e) {
    return false;
  }
}

bool _containsData(html_dom.Element element, String? args) {
  final data = args ?? '';
  if (element.localName == 'script' || element.localName == 'style') {
    return element.text.toLowerCase().contains(data.toLowerCase());
  }
  return false;
}

bool _containsWholeText(html_dom.Element element, String? args) {
  final text = args ?? '';
  return _getWholeText(element).contains(text);
}

bool _containsWholeOwnText(html_dom.Element element, String? args) {
  final text = args ?? '';
  return _getWholeOwnText(element).contains(text);
}

bool _matchesWholeText(html_dom.Element element, String? args) {
  if (args == null) return false;
  try {
    final reg = RegExp(args);
    return reg.hasMatch(_getWholeText(element));
  } catch (e) {
    return false;
  }
}

bool _matchesWholeOwnText(html_dom.Element element, String? args) {
  if (args == null) return false;
  try {
    final reg = RegExp(args);
    return reg.hasMatch(_getWholeOwnText(element));
  } catch (e) {
    return false;
  }
}

bool _isSelector(html_dom.Element element, String? args) {
  if (args == null) return false;
  final selectors = args.split(',').map((s) => s.trim()).toList();
  for (final sel in selectors) {
    try {
      final parsed = pseudom.parse(sel.replaceAll(':not', ':inot'));
      if (parsed.selectFirst(element) != null) return true;
    } catch (_) {}
  }
  return false;
}

bool _firstChild(html_dom.Element element, String? args) {
  return element.previousElementSibling == null;
}

bool _lastChild(html_dom.Element element, String? args) {
  return element.nextElementSibling == null;
}

bool _firstOfType(html_dom.Element element, String? args) {
  final parent = element.parent;
  if (parent == null) return false;
  final siblings = parent.children.where(
    (e) => e.localName == element.localName,
  );
  return siblings.first == element;
}

bool _lastOfType(html_dom.Element element, String? args) {
  final parent = element.parent;
  if (parent == null) return false;
  final siblings = parent.children.where(
    (e) => e.localName == element.localName,
  );
  return siblings.last == element;
}

bool _onlyChild(html_dom.Element element, String? args) {
  return element.previousElementSibling == null &&
      element.nextElementSibling == null;
}

bool _onlyOfType(html_dom.Element element, String? args) {
  final parent = element.parent;
  if (parent == null) return false;
  final siblings = parent.children.where(
    (e) => e.localName == element.localName,
  );
  return siblings.length == 1;
}

bool _empty(html_dom.Element element, String? args) {
  return element.children.isEmpty && element.text.trim().isEmpty;
}

bool _root(html_dom.Element element, String? args) {
  return element.parent == null;
}

bool _lt(html_dom.Element element, String? args) {
  if (args == null) return false;
  final n = int.tryParse(args);
  if (n == null) return false;
  final parent = element.parent;
  if (parent == null) return false;
  final index = parent.children.indexOf(element);
  return index < n;
}

bool _gt(html_dom.Element element, String? args) {
  if (args == null) return false;
  final n = int.tryParse(args);
  if (n == null) return false;
  final parent = element.parent;
  if (parent == null) return false;
  final index = parent.children.indexOf(element);
  return index > n;
}

bool _eq(html_dom.Element element, String? args) {
  if (args == null) return false;
  final n = int.tryParse(args);
  if (n == null) return false;
  final parent = element.parent;
  if (parent == null) return false;
  final index = parent.children.indexOf(element);
  return index == n;
}

void _initPseudoSelector() {
  if (_pseudoSelectorInitialized) return;
  _pseudoSelectorInitialized = true;
  pseudom.PseudoSelector.handlers['nth-child'] = _nthChild;
  pseudom.PseudoSelector.handlers['nth-last-child'] = _nthLastChild;
  pseudom.PseudoSelector.handlers['nth-of-type'] = _nthOfType;
  pseudom.PseudoSelector.handlers['nth-last-of-type'] = _nthLastOfType;
  pseudom.PseudoSelector.handlers['has'] = _has;
  pseudom.PseudoSelector.handlers['inot'] = _inot;
  pseudom.PseudoSelector.handlers['contains'] = _contains;
  pseudom.PseudoSelector.handlers['containsOwn'] = _containsOwn;
  pseudom.PseudoSelector.handlers['containsData'] = _containsData;
  pseudom.PseudoSelector.handlers['containsWholeText'] = _containsWholeText;
  pseudom.PseudoSelector.handlers['containsWholeOwnText'] =
      _containsWholeOwnText;
  pseudom.PseudoSelector.handlers['matches'] = _matches;
  pseudom.PseudoSelector.handlers['matchesWholeText'] = _matchesWholeText;
  pseudom.PseudoSelector.handlers['matchesWholeOwnText'] = _matchesWholeOwnText;
  pseudom.PseudoSelector.handlers['is'] = _isSelector;
  pseudom.PseudoSelector.handlers['last-child'] = _lastChild;
  pseudom.PseudoSelector.handlers['first-child'] = _firstChild;
  pseudom.PseudoSelector.handlers['first-of-type'] = _firstOfType;
  pseudom.PseudoSelector.handlers['last-of-type'] = _lastOfType;
  pseudom.PseudoSelector.handlers['only-child'] = _onlyChild;
  pseudom.PseudoSelector.handlers['only-of-type'] = _onlyOfType;
  pseudom.PseudoSelector.handlers['empty'] = _empty;
  pseudom.PseudoSelector.handlers['root'] = _root;
  pseudom.PseudoSelector.handlers['lt'] = _lt;
  pseudom.PseudoSelector.handlers['gt'] = _gt;
  pseudom.PseudoSelector.handlers['eq'] = _eq;
}

String _regHrefMatcher(String input) {
  try {
    RegExp exp = RegExp(r'href="([^"]+)"');
    Iterable<Match> matches = exp.allMatches(input);
    return matches.first.group(1)!;
  } catch (_) {
    return "";
  }
}

String _regDataSrcMatcher(String input) {
  try {
    RegExp exp = RegExp(r'data-src="([^"]+)"');
    Iterable<Match> matches = exp.allMatches(input);
    return matches.first.group(1)!;
  } catch (_) {
    return "";
  }
}

String _regSrcMatcher(String input) {
  try {
    RegExp exp = RegExp(r'src="([^"]+)"');
    Iterable<Match> matches = exp.allMatches(input);
    return matches.first.group(1)!;
  } catch (_) {
    return "";
  }
}

String _regImgMatcher(String input) {
  try {
    RegExp exp = RegExp(r'img="([^"]+)"');
    Iterable<Match> matches = exp.allMatches(input);
    return matches.first.group(1)!;
  } catch (_) {
    return "";
  }
}

List<html_dom.Element> _select(html_dom.Element dom, String selector) {
  try {
    final results = dom.querySelectorAll(selector);
    if (results.isNotEmpty) {
      return results;
    }
  } catch (_) {}

  try {
    _initPseudoSelector();
    final fixedSelector = selector.replaceAll(':not', ':inot');
    final results = pseudom.parse(fixedSelector).select(dom).toList();
    return results;
  } catch (err) {
    return [];
  }
}

html_dom.Element? _selectFirst(html_dom.Element dom, String selector) {
  try {
    final result = dom.querySelector(selector);
    if (result != null) {
      return result;
    }
  } catch (_) {}

  try {
    _initPseudoSelector();
    final fixedSelector = selector.replaceAll(':not', ':inot');
    final result = pseudom.parse(fixedSelector).selectFirst(dom);
    return result;
  } catch (err) {
    return null;
  }
}

List<html_dom.Element> _docSelect(html_dom.Document doc, String selector) {
  final dom = doc.documentElement;
  if (dom == null) return [];
  return _select(dom, selector);
}

html_dom.Element? _docSelectFirst(html_dom.Document doc, String selector) {
  final dom = doc.documentElement;
  if (dom == null) return null;
  return _selectFirst(dom, selector);
}

String _docXpathFirst(html_dom.Document doc, String xpath) {
  final dom = doc.documentElement;
  if (dom == null) return "";
  return _eleXpathFirst(dom, xpath);
}

String _eleXpathFirst(html_dom.Element element, String xpath) {
  try {
    var htmlXPath = HtmlXPath.node(element);
    var query = htmlXPath.query(xpath);
    return query.attr ?? "";
  } catch (_) {
    return "";
  }
}

List<String> _docXpath(html_dom.Document doc, String xpath) {
  final dom = doc.documentElement;
  if (dom == null) return [];
  return _eleXpath(dom, xpath);
}

List<String> _eleXpath(html_dom.Element element, String xpath) {
  try {
    var htmlXPath = HtmlXPath.node(element);
    var query = htmlXPath.query(xpath);
    if (query.nodes.length > 1) {
      return query.attrs.map((e) => e?.trim() ?? "").toList();
    }
    return [];
  } catch (_) {
    return [];
  }
}
