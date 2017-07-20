import 'dart:async';
import 'dart:io';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_hot/angel_hot.dart';
import 'package:angel_graphql/angel_graphql.dart';

main() async {
  var hot = new HotReloader(() async {
    var app = new Angel()..storeOriginalBuffer = true;
    app.use('/api/todos', new MapService());
    app.all('/graphql', graphQLHTTP('api/todos', graphiql: false));
    app.after.add(() => throw new AngelHttpException.notFound());

    var todoService = app.service('api/todos');
    await todoService
        .create({'text': 'Clean your room!', 'completed': true});

    app.errorHandler =
        (AngelHttpException e, RequestContext req, ResponseContext res) async {
      res
        ..statusCode = e.statusCode
        ..write(e.message)
        ..end();
    };

    app.fatalErrorStream.listen((e) {
      stderr..writeln('FATAL: ${e.error}')..writeln(e.stack);
      new Future.sync(() {
        e.request.response..writeln('FATAL: ${e.error}')..writeln(e.stack);
        return e.request.response.close();
      }).catchError((res) {
        // Whoops!
        stderr.writeln('Couldn\'t set fatal message: $res');
      });
    });

    return app;
  }, [Directory.current]);

  var server = await hot.startServer(InternetAddress.LOOPBACK_IP_V4, 3000);
  print(
      'GraphQL example listening at http://${server.address.address}:${server.port}');
}
