import 'dart:io';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_validate/angel_validate.dart';
import 'package:graphql_parser/graphql_parser.dart';
import 'package:graphql_schema/graphql_schema.dart';

final ContentType graphQlContentType =
    new ContentType('application', 'graphql');

final Validator graphQlPostBody = new Validator({
  'query*': isNonEmptyString,
  'operationName': isNonEmptyString,
  'variables': isMap
});

/// Mounts a GraphQL API.
RequestHandler graphQLHTTP(GraphQLSchema schema, {bool graphiql: true}) {
  return (RequestContext req, ResponseContext res) async {
    if (req.method != 'GET' && req.method != 'POST')
      throw new AngelHttpException.methodNotAllowed(
          message: 'This GraphQL endpoint only accepts GET and POST requests.');

    DocumentContext queryDoc;

    if (req.query.containsKey('query')) {
      queryDoc = new Parser(scan(req.query['query'])).parseDocument();
    } else if (req.method == 'GET') {
      throw new AngelHttpException.badRequest(
          message: 'Expected "query" in the request query string.');
    } else if (req.method == 'POST') {
      if (req.app.storeOriginalBuffer == true &&
          req.headers.contentType?.mimeType == graphQlContentType.mimeType) {
        queryDoc = new Parser(
                scan(new String.fromCharCodes(await req.lazyOriginalBuffer())))
            .parseDocument();
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

    // Now that we have a document, do something...
  };
}
