import 'dart:convert';
import 'package:flutter_js/flutter_js.dart';
import 'package:html/dom.dart' as html_dom;
import 'package:html/parser.dart' as html_parser;
import 'package:pseudom/pseudom.dart' as pseudom;
import 'package:xpath_selector_html_parser/xpath_selector_html_parser.dart';

class JsDomSelector {
  final JavascriptRuntime runtime;
  JsDomSelector(this.runtime);

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

  void dispose() {
    _clearCache();
  }

  void init() {
    runtime.onMessage('parse_html', (dynamic args) {
      final html = args[0] as String;
      final doc = html_parser.parse(html);
      _documentKey++;
      _documents[_documentKey] = doc;
      return _documentKey;
    });

    runtime.onMessage('get_doc_element', (dynamic args) {
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

    runtime.onMessage('get_doc_string', (dynamic args) {
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

    runtime.onMessage('get_element_string', (dynamic args) {
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

    runtime.onMessage('doc_select_first', (dynamic args) {
      final docKey = _asInt(args[0]);
      final selector = args[1] as String;
      final doc = _documents[docKey];
      _elementKey++;
      _elements[_elementKey] = doc == null
          ? null
          : _docSelectFirst(doc, selector);
      return _elementKey;
    });

    runtime.onMessage('ele_selectFirst', (dynamic args) {
      final selector = args[0] as String;
      final key = _asInt(args[1]);
      final element = _elements[key];
      _elementKey++;
      _elements[_elementKey] = element == null
          ? null
          : _selectFirst(element, selector);
      return _elementKey;
    });

    runtime.onMessage('ele_element_sibling', (dynamic args) {
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

    runtime.onMessage('ele_attr', (dynamic args) {
      final attrName = args[0] as String;
      final key = _asInt(args[1]);
      return _elements[key]?.attributes[attrName] ?? "";
    });

    runtime.onMessage('doc_attr', (dynamic args) {
      final docKey = _asInt(args[0]);
      final attr = args[1] as String;
      final doc = _documents[docKey];
      return doc?.attributes[attr] ?? "";
    });

    runtime.onMessage('ele_has_attr', (dynamic args) {
      final attr = args[0] as String;
      final key = _asInt(args[1]);
      return _elements[key]?.attributes.containsKey(attr) ?? false;
    });

    runtime.onMessage('doc_has_attr', (dynamic args) {
      final docKey = _asInt(args[0]);
      final attr = args[1] as String;
      final doc = _documents[docKey];
      return doc?.attributes.containsKey(attr) ?? false;
    });

    runtime.onMessage('doc_xpath_first', (dynamic args) {
      final docKey = _asInt(args[0]);
      final xpath = args[1] as String;
      final doc = _documents[docKey];
      return doc == null ? "" : _docXpathFirst(doc, xpath);
    });

    runtime.onMessage('ele_xpathFirst', (dynamic args) {
      final xpath = args[0] as String;
      final key = _asInt(args[1]);
      final element = _elements[key];
      return element == null ? "" : _eleXpathFirst(element, xpath);
    });

    runtime.onMessage('xpathFirst', (dynamic args) {
      final xpath = args[0] as String;
      final key = _asInt(args[1]);
      final element = _elements[key];
      return element == null ? "" : _eleXpathFirst(element, xpath);
    });

    runtime.onMessage('doc_xpath', (dynamic args) {
      final docKey = _asInt(args[0]);
      final xpath = args[1] as String;
      final doc = _documents[docKey];
      return json.encode(doc == null ? <String>[] : _docXpath(doc, xpath));
    });

    runtime.onMessage('ele_xpath', (dynamic args) {
      final xpath = args[0] as String;
      final key = _asInt(args[1]);
      final element = _elements[key];
      return json.encode(
        element == null ? <String>[] : _eleXpath(element, xpath),
      );
    });

    runtime.onMessage('xpath', (dynamic args) {
      final xpath = args[0] as String;
      final key = _asInt(args[1]);
      final element = _elements[key];
      return json.encode(
        element == null ? <String>[] : _eleXpath(element, xpath),
      );
    });

    runtime.onMessage('doc_get_elements_by', (dynamic args) {
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

    runtime.onMessage('ele_get_elements_by', (dynamic args) {
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

    runtime.onMessage('doc_get_element_by_id', (dynamic args) {
      final docKey = _asInt(args[0]);
      final id = args[1] as String;
      final doc = _documents[docKey];
      _elementKey++;
      _elements[_elementKey] = doc?.getElementById(id);
      return _elementKey;
    });

    runtime.onMessage('doc_select', (dynamic args) {
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

    runtime.onMessage('ele_select', (dynamic args) {
      final selector = args[0] as String;
      final key = _asInt(args[1]);
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

    runtime.evaluate('''
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
        : pseudom
                  .parse(args.replaceAll(':not', ':inot'))
                  .selectFirst(element) !=
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
        : pseudom
                  .parse(args.replaceAll(':not', ':inot'))
                  .selectFirst(element) ==
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
    pseudom.PseudoSelector.handlers['matchesWholeOwnText'] =
        _matchesWholeOwnText;
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
    _pseudoSelectorInitialized = true;
  }

  String _fixSelector(String selector) {
    return selector.replaceAll(':not', ':inot');
  }

  html_dom.Element? _docSelectFirst(html_dom.Document doc, String selector) {
    _initPseudoSelector();
    try {
      final dom = doc.documentElement;
      return pseudom.parse(_fixSelector(selector)).selectFirst(dom!);
    } catch (_) {
      return null;
    }
  }

  html_dom.Element? _selectFirst(html_dom.Element element, String selector) {
    _initPseudoSelector();
    try {
      return pseudom.parse(_fixSelector(selector)).selectFirst(element);
    } catch (_) {
      return null;
    }
  }

  List<html_dom.Element> _docSelect(html_dom.Document doc, String selector) {
    _initPseudoSelector();
    try {
      final dom = doc.documentElement;
      return pseudom.parse(_fixSelector(selector)).select(dom!).toList();
    } catch (_) {
      return [];
    }
  }

  List<html_dom.Element> _select(html_dom.Element element, String selector) {
    _initPseudoSelector();
    try {
      return pseudom.parse(_fixSelector(selector)).select(element).toList();
    } catch (_) {
      return [];
    }
  }

  String _docXpathFirst(html_dom.Document doc, String xpath) {
    final dom = doc.documentElement;
    if (dom == null) return "";
    var htmlXPath = HtmlXPath.node(dom);
    var query = htmlXPath.query(xpath);
    return query.attr ?? "";
  }

  String _eleXpathFirst(html_dom.Element element, String xpath) {
    var htmlXPath = HtmlXPath.node(element);
    var query = htmlXPath.query(xpath);
    return query.attr ?? "";
  }

  List<String> _docXpath(html_dom.Document doc, String xpath) {
    final dom = doc.documentElement;
    if (dom == null) return [];
    var htmlXPath = HtmlXPath.node(dom);
    var query = htmlXPath.query(xpath);
    if (query.nodes.length > 1) {
      return query.attrs.map((e) => e!.trim()).toList();
    }
    return [];
  }

  List<String> _eleXpath(html_dom.Element element, String xpath) {
    var htmlXPath = HtmlXPath.node(element);
    var query = htmlXPath.query(xpath);
    if (query.nodes.length > 1) {
      return query.attrs.map((e) => e!.trim()).toList();
    }
    return [];
  }

  String _regSrcMatcher(String html) {
    try {
      return RegExp(
            "src=['\"]([^'\"]*)['\"]",
            caseSensitive: false,
          ).firstMatch(html)?.group(1) ??
          "";
    } catch (_) {
      return "";
    }
  }

  String _regImgMatcher(String html) {
    try {
      return RegExp(
            "img=['\"]([^'\"]*)['\"]",
            caseSensitive: false,
          ).firstMatch(html)?.group(1) ??
          "";
    } catch (_) {
      return "";
    }
  }

  String _regHrefMatcher(String html) {
    try {
      return RegExp(
            "href=['\"]([^'\"]*)['\"]",
            caseSensitive: false,
          ).firstMatch(html)?.group(1) ??
          "";
    } catch (_) {
      return "";
    }
  }

  String _regDataSrcMatcher(String html) {
    try {
      return RegExp(
            "data-src=['\"]([^'\"]*)['\"]",
            caseSensitive: false,
          ).firstMatch(html)?.group(1) ??
          "";
    } catch (_) {
      return "";
    }
  }
}
