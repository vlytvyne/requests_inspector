import 'dart:async';
import 'package:graphql/client.dart';
import 'package:gql/language.dart';

import '../requests_inspector.dart';

class GraphQLInspectorLink extends Link {
  GraphQLInspectorLink(this._link);

  final Link _link;

  @override
  Stream<Response> request(Request request, [NextLink? forward]) {
    final link = _link;

    if (link is HttpLink)
      return _handleHttpRequest(link, request, forward);
    else if (link is WebSocketLink)
      return _handleWebSocketRequest(link, request, forward);
    else
      return link.request(request, forward);
  }

  Stream<Response> _handleHttpRequest(
    HttpLink link,
    Request request,
    NextLink? forward,
  ) async* {
    await for (final response in link.request(request, forward)) {
      final responseContext = response.context.entry<HttpLinkResponseContext>();
      InspectorController().addNewRequest(
        RequestDetails(
          requestName: request.operation.operationName,
          requestMethod: RequestMethod.POST,
          requestBody: request.variables,
          headers: responseContext?.headers,
          url: link.uri.toString(),
          responseBody: response.response,
          statusCode: responseContext?.statusCode ?? 0,
        ),
      );
      yield response;
    }
  }

  Stream<Response> _handleWebSocketRequest(
    WebSocketLink link,
    Request request,
    NextLink? forward,
  ) async* {
    await for (final response in link.request(request, forward)) {
      InspectorController().addNewRequest(
        RequestDetails(
          requestName: request.operation.operationName ?? 'GraphQL',
          requestMethod: RequestMethod.WS,
          requestBody: request.variables,
          url: link.url,
          responseBody: response.response,
          statusCode: 200,
        ),
      );
      yield response;
    }
  }
}
