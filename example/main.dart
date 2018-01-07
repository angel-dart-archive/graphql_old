import 'dart:async';
import 'dart:io';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_hot/angel_hot.dart';
import 'package:angel_graphql/angel_graphql.dart';
import 'package:glob/glob.dart';
import 'package:logging/logging.dart';
import 'pretty_logging.dart';

main() async {
  var hot = new HotReloader(() async {
    var app = new Angel()..storeOriginalBuffer = true;
    app.logger = new Logger.detached('angel')..onRecord.listen(prettyLog);

    app.use('/api/todos', new MapService());
    app.all('/graphql', graphQLHTTP('api/todos', graphiql: !app.isProduction));
    app.use(() => throw new AngelHttpException.notFound());

    var todoService = app.service('api/todos');
    await todoService.create({'text': 'Clean your room!', 'completed': true});

    app.errorHandler =
        (AngelHttpException e, RequestContext req, ResponseContext res) async {
      res
        ..statusCode = e.statusCode
        ..write(e.message)
        ..end();
    };

    return app;
  }, [
    new Glob('lib/**/*.dart'),
  ]);

  var server = await hot.startServer(InternetAddress.LOOPBACK_IP_V4, 3000);
  print(
      'GraphQL example listening at http://${server.address.address}:${server.port}');
}
