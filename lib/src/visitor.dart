import 'package:graphql_parser/graphql_parser.dart';

class QueryVisitor {
  const QueryVisitor();

  visitDocument(DocumentContext ctx, inputData) {
    return ctx.definitions.fold(inputData, (o, def) => visitDefinition(def, o));
  }

  visitDefinition(DefinitionContext ctx, inputData) {
    if (ctx is OperationDefinitionContext)
      return visitOperationDefinition(ctx, inputData);
    else return visitFragmentDefinition(ctx, inputData);
  }

  visitOperationDefinition(OperationDefinitionContext ctx, inputData) {

  }

  visitFragmentDefinition(FragmentDefinitionContext ctx, inputData) {
    throw new UnsupportedError('Fragments are not yet supported.');
  }
}
