import 'dart:io';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_validate/angel_validate.dart';
import 'package:graphql/graphql.dart';
import 'package:graphql_parser/graphql_parser.dart';
import 'package:graphql_schema/graphql_schema.dart';

final ContentType graphQlContentType =
    new ContentType('application', 'graphql');

final Validator graphQlPostBody = new Validator({
  'query*': isNonEmptyString,
  'operationName': isNonEmptyString,
  'variables': isMap
});

/// Mounts a GraphQL API that queries the [Service] at the given [servicePath].
///
/// If [graphiql] is set to `true`, then responses will fallback to rendering the GraphIQL interface.
/// If it is `null`, then it will default to `!app.isProduction`.
///
/// If your service has pagination hooks attached, set [asPaginated] to `true`.
/// Save yourself the headache.
RequestHandler graphQLHTTP(Pattern servicePath,
    {GraphQLSchema schema, bool graphiql, bool asPaginated}) {
  GraphQL _graphql;
  Service _service;
  bool _showGraphiql = graphiql;

  return (RequestContext req, ResponseContext res) async {
    if (req.method != 'GET' && req.method != 'POST')
      throw new AngelHttpException.methodNotAllowed(
          message: 'This GraphQL endpoint only accepts GET and POST requests.');

    DocumentContext queryDoc;
    _service ??= req.app.service(servicePath);

    _graphql ??= new GraphQL(() async {
      var data = await _service.index();
      return asPaginated == true ? data['data'] : data;
    }, schema: schema);

    _showGraphiql ??= !req.app.isProduction;

    if (req.method == 'GET') {
      // Use `uri.queryParameters` because `body_parser` can't handle this.
      if (req.uri.queryParameters.containsKey('query')) {
        queryDoc =
            new Parser(scan(req.uri.queryParameters['query'])).parseDocument();
      } else if (_showGraphiql) {
        // TODO: GraphiQL
        return 'graphiql';
      } else {
        throw new AngelHttpException.badRequest(
            message: 'Expected "query" in the request query string.');
      }
    }

    // Different scenario for POST, because we can write data.
    else {
      if (req.headers.contentType?.mimeType == graphQlContentType.mimeType) {
        var buf = await req.lazyOriginalBuffer();

        if (buf == null) {
          throw new StateError(
              'graphQLHTTP cannot parse application/graphql bodies if app.storeOriginalBuffer is not `true`.');
        }

        var queryString = new String.fromCharCodes(buf);
        queryDoc = new Parser(scan(queryString)).parseDocument();
      } else {
        try {
          var data = graphQlPostBody.enforce(await req.lazyBody());
          queryDoc = new Parser(scan(data['query'])).parseDocument();
        } on ValidationException catch (e) {
          throw new AngelHttpException.badRequest(
              message: e.message, errors: e.errors);
        }
      }
    }

    // Execute...
    if (queryDoc == null) {
      // TODO: Throw error
    } else {
      // TODO: Which data to query???
      return await _graphql.query(queryDoc);
    }

    return false;

    // Now that we have a document, do something...
  };
}
