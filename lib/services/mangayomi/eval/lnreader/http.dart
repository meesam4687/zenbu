import 'dart:convert';
import 'dart:io';
import 'package:flutter_js/flutter_js.dart';
import 'package:http/http.dart' as http;

class JsHttpClient {
  late JavascriptRuntime runtime;
  JsHttpClient(this.runtime);

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
class Response {
  constructor(url, result) {
    this.url = url;
    this.response = typeof result === 'string' ? JSON.parse(result) : result;
  }
  get status() {
    return this.response.statusCode || 200;
  }
  get statusText() {
    return this.response.reasonPhrase || "OK";
  }
  get ok() {
    return this.status >= 200 && this.status <= 299;
  }
  get redirected() {
    return !!this.response.isRedirect;
  }
  get headers() {
    return this.response.headers || {};
  }
  get body() {
    return this.response.body || "";
  }
  json() {
    const val = JSON.parse(this.body);
    return new Promise(function(resolve, reject) {
      resolve(val);
    });
  }
  text() {
    const val = this.body;
    return new Promise(function(resolve, reject) {
      resolve(val);
    });
  }
}

async function fetchApi(url, init) {
  const method = init?.method ? init.method.toLowerCase() : "get";
  const result = await sendMessage(
    "http_" + method,
    JSON.stringify([url, init?.headers, init?.body])
  );
  return new Response(url, result);
}
''');
  }
}

Future<String> _toHttpResponse(String method, dynamic args) async {
  final List parsedArgs = args is List ? args : jsonDecode(args.toString());
  final url = parsedArgs[0] as String;
  final headersRaw = parsedArgs[1] as Map?;
  final Map<String, String> headers = {};
  if (headersRaw != null) {
    headersRaw.forEach((k, v) => headers[k.toString()] = v.toString());
  }

  final body = parsedArgs.length >= 3 ? parsedArgs[2] : null;

  var request = http.Request(method, Uri.parse(url));
  request.headers.addAll(headers);

  if ((request.headers[HttpHeaders.contentTypeHeader]?.contains(
        "application/json",
      )) ??
      false) {
    if (body != null) {
      request.body = body is String ? body : json.encode(body);
    }
    http.StreamedResponse response = await request.send();
    final responseBody = await response.stream.bytesToString();
    Map<String, dynamic> resMap = {
      'body': responseBody,
      'headers': response.headers,
      'isRedirect': response.isRedirect,
      'reasonPhrase': response.reasonPhrase,
      'statusCode': response.statusCode,
    };
    return jsonEncode(resMap);
  }

  String? formData;
  if (body is Map && body.containsKey("_data")) {
    formData = (body["_data"] as List<dynamic>)
        .map(
          (e) =>
              "${Uri.encodeQueryComponent(e[0].toString())}"
              "=${Uri.encodeQueryComponent(e[1].toString())}",
        )
        .join("&");
    headers["content-type"] =
        "application/x-www-form-urlencoded; charset=UTF-8";
  }

  final client = http.Client();
  try {
    final response = await switch (method) {
      "HEAD" => client.head(Uri.parse(url), headers: headers),
      "GET" => client.get(Uri.parse(url), headers: headers),
      "POST" => client.post(
        Uri.parse(url),
        headers: headers,
        body: formData ?? body,
      ),
      "PUT" => client.put(
        Uri.parse(url),
        headers: headers,
        body: formData ?? body,
      ),
      "DELETE" => client.delete(
        Uri.parse(url),
        headers: headers,
        body: formData ?? body,
      ),
      _ => client.patch(
        Uri.parse(url),
        headers: headers,
        body: formData ?? body,
      ),
    };

    Map<String, dynamic> resMap = {
      'body': response.body,
      'headers': response.headers,
      'isRedirect': response.isRedirect,
      'reasonPhrase': response.reasonPhrase,
      'statusCode': response.statusCode,
    };
    return jsonEncode(resMap);
  } finally {
    client.close();
  }
}
