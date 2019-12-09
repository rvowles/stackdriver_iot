import 'dart:io';

import 'package:args/args.dart';
import 'package:googleapis/monitoring/v3.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:iot_api/api.dart';
import 'package:logging/logging.dart';
import 'package:stackdriver_iot/pusher.dart';
import 'package:stackdriver_iot/temperature_pusher.dart';

final _log = Logger('stackdriver');

class StackdriverPusherClient {
  String _projectName;
  String _credsFilename;
  MonitoringApi _api;
  List<Pusher> _pushers = [];

  StackdriverPusherClient(List<String> arguments) {
    final args = ArgParser();
    args.addOption('creds', defaultsTo: Platform.environment['HOME'] + '/.stackdrivercred.json');
    args.addOption('project', defaultsTo: 'kesteven-corner');
    final config = args.parse(arguments);
    _projectName = 'projects/' + config['project']; // project name
    _credsFilename = config['creds'];
  }

  void init({bool setupMetrics = true}) async {
    final client = http.Client();

    final scopes = [MonitoringApi.MonitoringScope];

    final accountCredentials = ServiceAccountCredentials.fromJson(
        await File(_credsFilename).readAsString());

    final credentials =
        await obtainAccessCredentialsViaServiceAccount(
            accountCredentials, scopes, client);

    final authClient = authenticatedClient(client, credentials);

    _api = MonitoringApi(authClient);

    if (setupMetrics) {
      _pushers = [
        TemperaturePusher(_api, _projectName)
      ];

      final existingMetrics =
        await _api.projects.metricDescriptors.list(_projectName);

      await _pushers.forEach((p) async => await p.setupMetrics(existingMetrics));
    } else {
      _pushers.forEach((p) => p.setApi(_api));
    }
  }

  void processTimeseriesData(Timeseries data) async {
    if (data.mote == null) {
      _log.severe('Mote is null from ${data}');
    } else if (data.source == null) {
      _log.severe('Source is null from ${data}');
    } else {
      for (final p in _pushers) {
        var ok = await p.process(data);
        if (!ok) {
          _log.info('process failed, attempting to reconnect');
          await init(setupMetrics: false);
          ok = await p.process(data);
          _log.info('failed a second time to process data. giving up');
        }
      }
    }
  }

  void close() {
  }
}




