import 'package:iot_api/api.dart';

import 'numeric_metric_transformer.dart';
import 'metric_transformer.dart';

List<MetricTransformer> availableTransformers = [
  TemperatureTransformer(),
  MoistureTransformer(),
  PressureTransformer(),
  HumidityTransformer()
];

class TemperatureTransformer extends DoubleMetricTransformer {
  TemperatureTransformer() : super('temperature', 'Temperature in deg C', 'Temperature');

  @override
  PointType getType() {
    return PointType.TEMP_C;
  }
}

class MoistureTransformer extends IntegerMetricTransformer {
  MoistureTransformer() : super('soil_moisture', 'Analog reading of soil moisture', 'Soil Moisture');

  @override
  PointType getType() {
    return PointType.ANALOG_1024;
  }
}

class PressureTransformer extends DoubleMetricTransformer {
  PressureTransformer() : super('pressure', 'Atmospheric Pressure in hPascals', 'Atmospheric Pressure');

  @override
  PointType getType() {
    return PointType.PRESSURE_HPA;
  }
}

class HumidityTransformer extends DoubleMetricTransformer {
  HumidityTransformer() : super('humidity', 'Relative humidity in percentage', 'Relative Humidity');

  @override
  PointType getType() {
    return PointType.HUMIDITY_PC;
  }
}

