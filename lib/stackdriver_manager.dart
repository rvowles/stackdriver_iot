import 'dart:io';

import 'package:args/args.dart';
import 'package:googleapis/monitoring/v3.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:iot_api/api.dart';
import 'package:logging/logging.dart';
import 'package:stackdriver_iot/metric_transformer.dart';
import 'package:stackdriver_iot/transformers.dart';

final _log = Logger('stackdriver');

class StackdriverManager {
  String _projectName;
  String _credsFilename;
  MonitoringApi _api;
  List<MetricTransformer> _pushers = []..addAll(availableTransformers);

  StackdriverManager(List<String> arguments) {
    final args = ArgParser();
    args.addOption('creds',
        defaultsTo: Platform.environment['HOME'] + '/.stackdrivercred.json');
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

    final credentials = await obtainAccessCredentialsViaServiceAccount(
        accountCredentials, scopes, client);

    final authClient = authenticatedClient(client, credentials);

    _api = MonitoringApi(authClient);

    if (setupMetrics) {
      final existingMetrics =
          await _api.projects.metricDescriptors.list(_projectName);

      await _pushers.forEach((p) async =>
          await p.setupMetrics(_api, _projectName, existingMetrics));
    }
  }

  void processTimeseriesData(Timeseries data) async {
    if (data.mote == null) {
      _log.severe('Mote is null from ${data}');
    } else if (data.source == null) {
      _log.severe('Source is null from ${data}');
    } else {
      List<TimeSeries> series = _pushers
          .map((p) => p.process(data))
          .where((result) => result != null)
          .toList();

      var ok = await _pushTimeSeries(series, data);
      if (!ok ) {
        _log.warning("Timeout or other failure, attempting again.");
        await init(setupMetrics: false);
        ok = await _pushTimeSeries(series, data);
        if (!ok) {
          _log.severe('failed again');
        }
      }
    }
  }

  Future<bool> _pushTimeSeries(List<TimeSeries> series, Timeseries data) async {
    try {
      await _api.projects.timeSeries.create(
          CreateTimeSeriesRequest()..timeSeries = series, _projectName);
      _log.info('published time series data for ${data}');
      return true;
    } catch (e, s) {
      _log.severe('Failed to publish point type ${data}', e, s);
      return false;
    }
  }

  void close() {}
}
