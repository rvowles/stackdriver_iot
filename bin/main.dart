import 'dart:convert';

import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;
import 'package:iot_api/api.dart' as api;

void main(List<String> arguments) async {
//  StackdriverPusherClient client = StackdriverPusherClient(arguments);
//  client.init();

  var handler = const shelf.Pipeline().addMiddleware(shelf.logRequests())
      .addHandler(_dispatchRequest);

  await io.serve(handler, 'localhost', 3000).then((server) {
    print('Serving at http://${server.address.host}:${server.port}');
  });
}

Future<shelf.Response> _dispatchRequest(shelf.Request request) async {
  print('path ${request.url.path} method: ${request.method}');
  if (request.url.path == 'timeseries' && request.method == 'PUT') {
    if (request.headers['content-type'] == 'application/json') {
      final data = await utf8.decodeStream(request.read());
      print(api.Timeseries.fromJson(jsonDecode(data)));
      return shelf.Response.ok('saved');
    } else {
      return shelf.Response(405, body: 'invalid method or content-type', headers: {'content-type': 'text/plain'});
    }
  } else {
    return shelf.Response.notFound('Request for "${request.url}" not found.');
  }

}
