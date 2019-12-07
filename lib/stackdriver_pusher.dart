import 'dart:io';

import 'package:args/args.dart';
import 'package:googleapis/monitoring/v3.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:iot_api/api.dart';
import 'package:stackdriver_iot/pusher.dart';
import 'package:stackdriver_iot/temperature_pusher.dart';

//final _log = Logger('stackdriver');

class StackdriverPusherClient {
  final http.Client client;
  String _projectName;
  String _credsFilename;
  MonitoringApi _api;
  List<Pusher> _pushers = [];

  StackdriverPusherClient(List<String> arguments) : client = http.Client() {
    final args = ArgParser();
    args.addOption('creds', defaultsTo: Platform.environment['HOME'] + '/.stackdrivercred.json');
    args.addOption('project', defaultsTo: 'kesteven-corner');
    final config = args.parse(arguments);
    _projectName = 'projects/' + config['project']; // project name
    _credsFilename = config['creds'];
  }

  void init() async {
    final scopes = [MonitoringApi.MonitoringScope];

    final accountCredentials = ServiceAccountCredentials.fromJson(
        await File(_credsFilename).readAsString());

    final credentials =
        await obtainAccessCredentialsViaServiceAccount(
            accountCredentials, scopes, client);

    final authClient = authenticatedClient(client, credentials);

    _api = MonitoringApi(authClient);

    final existingMetrics =
        await _api.projects.metricDescriptors.list(_projectName);

    _pushers = [
      TemperaturePusher(_api, _projectName)
    ];

    await _pushers.forEach((p) async => await p.setupMetrics(existingMetrics));
  }

  void processTimeseriesData(Timeseries data) async {
    _pushers.forEach((p) => p.process(data));
  }

  void close() {
    client.close();
  }
}




