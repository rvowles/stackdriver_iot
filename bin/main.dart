import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;
import 'package:iot_api/api.dart' as api;
import 'package:stackdriver_iot/stackdriver_manager.dart';

final _log = Logger('iot');
StackdriverManager client;

void main(List<String> arguments) async {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((LogRecord rec) {
    print('${rec.level.name}: ${rec.time}: ${rec.message}');
  });

  client = StackdriverManager(arguments);
  await client.init();

  var handler = const shelf.Pipeline().addMiddleware(shelf.logRequests())
      .addHandler(_dispatchRequest);

  await io.serve(handler, '0.0.0.0', 3000).then((server) {
    _log.info('Serving at http://${server.address.host}:${server.port}');
  });
}

Future<shelf.Response> _dispatchRequest(shelf.Request request) async {
  _log.info('path ${request.url.path} method: ${request.method}');
  if (request.url.path == 'timeseries' && request.method == 'PUT') {
    if (request.headers['content-type'] == 'application/json') {
      final data = await utf8.decodeStream(request.read());
      final timeSeries = api.Timeseries.fromJson(jsonDecode(data));
      print(timeSeries);
      client.processTimeseriesData(timeSeries);
      return shelf.Response.ok('saved');
    } else {
      return shelf.Response(405, body: 'invalid method or content-type', headers: {'content-type': 'text/plain'});
    }
  } else {
    return shelf.Response.notFound('Request for "${request.url}" not found.');
  }

}
