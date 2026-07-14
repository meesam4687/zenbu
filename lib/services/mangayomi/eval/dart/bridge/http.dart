import 'dart:convert';
import 'package:d4rt/d4rt.dart';
import 'package:http_interceptor/http_interceptor.dart';
import 'dart:io';
import 'package:http/io_client.dart';
import 'package:zenbu/services/mangayomi/eval/model/m_source.dart';

class HeaderInterceptor implements InterceptorContract {
  @override
  bool shouldInterceptRequest() => true;

  @override
  bool shouldInterceptResponse() => false;

  @override
  Future<BaseRequest> interceptRequest({required BaseRequest request}) async {
    final hasUserAgent = request.headers.keys.any(
      (k) => k.toLowerCase() == 'user-agent',
    );
    if (!hasUserAgent) {
      request.headers['User-Agent'] =
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';
    }
    final hasReferer = request.headers.keys.any(
      (k) => k.toLowerCase() == 'referer',
    );
    if (!hasReferer) {
      try {
        final origin = '${request.url.scheme}://${request.url.host}';
        request.headers['Referer'] = '$origin/';
      } catch (_) {}
    }
    return request;
  }

  @override
  Future<BaseResponse> interceptResponse({
    required BaseResponse response,
  }) async {
    return response;
  }
}

class MClient {
  static InterceptedClient init({
    MSource? source,
    Map<String, dynamic>? reqcopyWith,
  }) {
    final httpClient = HttpClient()
      ..badCertificateCallback = (cert, host, port) => true;
    final ioClient = IOClient(httpClient);
    return InterceptedClient.build(
      client: ioClient,
      interceptors: [HeaderInterceptor()],
    );
  }
}

class HttpBridge {
  final clientBridgedClass = BridgedClass(
    nativeType: InterceptedClient,
    name: 'Client',
    constructors: {
      '': (visitor, positionalArgs, namedArgs) {
        return MClient.init(
          source: positionalArgs.isNotEmpty
              ? positionalArgs[0] as MSource
              : null,
          reqcopyWith: positionalArgs.length > 1
              ? (jsonDecode(positionalArgs[1] as String) as Map)
                    .cast<String, dynamic>()
              : null,
        );
      },
    },
    methods: {
      'get': (visitor, target, positionalArgs, namedArgs) =>
          (target as Client).get(
            positionalArgs[0] as Uri,
            headers: namedArgs.get<Map?>('headers')?.cast(),
          ),
      'post': (visitor, target, positionalArgs, namedArgs) =>
          (target as Client).post(
            positionalArgs[0] as Uri,
            headers: namedArgs.get<Map?>('headers')?.cast(),
            body: namedArgs.get<Object?>('body'),
            encoding: namedArgs.get<Encoding?>('encoding'),
          ),
      'put': (visitor, target, positionalArgs, namedArgs) =>
          (target as Client).put(
            positionalArgs[0] as Uri,
            headers: namedArgs.get<Map?>('headers')?.cast(),
            body: namedArgs.get<Object?>('body'),
            encoding: namedArgs.get<Encoding?>('encoding'),
          ),
      'delete': (visitor, target, positionalArgs, namedArgs) =>
          (target as Client).delete(
            positionalArgs[0] as Uri,
            headers: namedArgs.get<Map?>('headers')?.cast(),
            body: namedArgs.get<Object?>('body'),
            encoding: namedArgs.get<Encoding?>('encoding'),
          ),
      'head': (visitor, target, positionalArgs, namedArgs) =>
          (target as Client).head(
            positionalArgs[0] as Uri,
            headers: namedArgs.get<Map?>('headers')?.cast(),
          ),
      'patch': (visitor, target, positionalArgs, namedArgs) =>
          (target as Client).patch(
            positionalArgs[0] as Uri,
            headers: namedArgs.get<Map?>('headers')?.cast(),
            body: namedArgs.get<Object?>('body'),
            encoding: namedArgs.get<Encoding?>('encoding'),
          ),
      'read': (visitor, target, positionalArgs, namedArgs) =>
          (target as Client).read(
            positionalArgs[0] as Uri,
            headers: namedArgs.get<Map?>('headers')?.cast(),
          ),
      'readBytes': (visitor, target, positionalArgs, namedArgs) =>
          (target as Client).readBytes(
            positionalArgs[0] as Uri,
            headers: namedArgs.get<Map?>('headers')?.cast(),
          ),
      'close': (visitor, target, positionalArgs, namedArgs) =>
          (target as Client).close(),
      'send': (visitor, target, positionalArgs, namedArgs) =>
          (target as Client).send(positionalArgs[0] as BaseRequest),
    },
  );
  final baseRequestBridgedClass = BridgedClass(
    nativeType: BaseRequest,
    name: 'BaseRequest',
    nativeNames: ['Request'],
    constructors: {
      '': (visitor, positionalArgs, namedArgs) {
        return BaseRequest;
      },
    },
    getters: {
      'contentLength': (visitor, target) =>
          (target as BaseRequest).contentLength,
      'headers': (visitor, target) => (target as BaseRequest).headers,
      'url': (visitor, target) => (target as BaseRequest).url,
      'persistentConnection': (visitor, target) =>
          (target as BaseRequest).persistentConnection,
      'method': (visitor, target) => (target as BaseRequest).method,
      'followRedirects': (visitor, target) =>
          (target as BaseRequest).followRedirects,
      'maxRedirects': (visitor, target) => (target as BaseRequest).maxRedirects,
      'finalized': (visitor, target) => (target as BaseRequest).finalized,
    },
  );
  final responseBridgedClass = BridgedClass(
    nativeType: Response,
    name: 'Response',
    constructors: {
      '': (visitor, positionalArgs, namedArgs) {
        return Response;
      },
    },
    getters: {
      'statusCode': (visitor, target) => (target as Response).statusCode,
      'body': (visitor, target) => (target as Response).body,
      'headers': (visitor, target) => (target as Response).headers,
      'isRedirect': (visitor, target) => (target as Response).isRedirect,
      'reasonPhrase': (visitor, target) => (target as Response).reasonPhrase,
      'contentLength': (visitor, target) => (target as Response).contentLength,
      'bodyBytes': (visitor, target) => (target as Response).bodyBytes,
      'persistentConnection': (visitor, target) =>
          (target as Response).persistentConnection,
      'request': (visitor, target) => (target as Response).request,
    },
  );
  final streamedResponseBridgedClass = BridgedClass(
    nativeType: StreamedResponse,
    name: 'StreamedResponse',
    constructors: {
      '': (visitor, positionalArgs, namedArgs) {
        return StreamedResponse;
      },
    },
    getters: {
      'statusCode': (visitor, target) =>
          (target as StreamedResponse).statusCode,
      'headers': (visitor, target) => (target as StreamedResponse).headers,
      'isRedirect': (visitor, target) =>
          (target as StreamedResponse).isRedirect,
      'reasonPhrase': (visitor, target) =>
          (target as StreamedResponse).reasonPhrase,
      'stream': (visitor, target) => (target as StreamedResponse).stream,
      'contentLength': (visitor, target) =>
          (target as StreamedResponse).contentLength,
      'persistentConnection': (visitor, target) =>
          (target as StreamedResponse).persistentConnection,
      'request': (visitor, target) => (target as StreamedResponse).request,
    },
  );
  final byteStreamBridgedClass = BridgedClass(
    nativeType: ByteStream,
    name: 'ByteStream',
    constructors: {
      '': (visitor, positionalArgs, namedArgs) {
        return ByteStream;
      },
    },
  );

  void registerBridgedClasses(D4rt interpreter) {
    interpreter.registerBridgedClass(
      baseRequestBridgedClass,
      'package:mangayomi/bridge_lib.dart',
    );
    interpreter.registerBridgedClass(
      clientBridgedClass,
      'package:mangayomi/bridge_lib.dart',
    );
    interpreter.registerBridgedClass(
      responseBridgedClass,
      'package:mangayomi/bridge_lib.dart',
    );
    interpreter.registerBridgedClass(
      streamedResponseBridgedClass,
      'package:mangayomi/bridge_lib.dart',
    );
    interpreter.registerBridgedClass(
      byteStreamBridgedClass,
      'package:mangayomi/bridge_lib.dart',
    );
  }
}
