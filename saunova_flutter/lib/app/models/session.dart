import 'dart:convert';

class Session {
  final String id;
  final int durationSeconds;
  final int humidityPercent;
  final int temperatureC;
  final DateTime startedAt;
  final DateTime stoppedAt;
  final String brief;
  final Map<String, dynamic> axisData;

  Session({
    required this.id,
    required this.durationSeconds,
    required this.humidityPercent,
    required this.temperatureC,
    required this.startedAt,
    required this.stoppedAt,
    required this.brief,
    required this.axisData,
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    final fixed = json['axis_data'].replaceAll("'", '"');

    final Map<String, dynamic> result = jsonDecode(fixed);
    final session = Session(
      id: json['_id'],
      durationSeconds: json['durationSeconds'].round(),
      humidityPercent: json['humidityPercent'].round(),
      temperatureC: json['temperatureC'].round(),
      startedAt: DateTime.parse(json['startedAt']),
      stoppedAt: DateTime.parse(json['stoppedAt']),
      brief: json['brief'],
      axisData: result,
    );
    //this gives us this:
    //   I/flutter ( 8280): │ 💡 Parsed session: Session(id: 6918dc775a98a195acde7094, durationSeconds: 27, humidityPercent: 12, temperatureC: 79, startedAt: 2025-11-15 20:02:32.360Z, stoppedAt: 2025-11-15 20:02:59.022Z, brief: Löyly moments were subtle, with a slight temperature rise at 14 seconds adding a gentle thrill.
    //   I/flutter ( 8280): │ 💡 The session was comforting, maintaining a cozy 68-70°C with a consistent 11% humidity.
    //   I/flutter ( 8280): │ 💡 The temperature curve was mostly stable, with a minor fluctuation around the midpoint.
    //   I/flutter ( 8280): │ 💡 Humidity held steady at 11%, providing a consistent and soothing sauna experience., axisData: {'x_axis': {'label': 'Time (seconds)', 'data': array([ 0,  2,  4,  6,  8, 10, 12, 14, 16, 18, 20, 22]), 'limits': (np.float64(-1.1), np.float64(23.1))}, 'y_axis_left': {'label': 'Temperature (°C)', 'data': array([69, 69, 69, 69, 68, 68, 68, 70, 70, 70, 70, 70]), 'limits': (np.float64(58.0), np.float64(80.0)), 'color': 'tab:red'}, 'y_axis_right': {'label': 'Humidity (%)', 'data': array([11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11]), 'limits': (np.float64(6.0), np.float64(16.0)), 'color': 'tab:blue'}})
    return session;
  }

  @override
  String toString() {
    return 'Session(id: $id, durationSeconds: $durationSeconds, humidityPercent: $humidityPercent, temperatureC: $temperatureC, startedAt: $startedAt, stoppedAt: $stoppedAt, brief: $brief, axisData: $axisData)';
  }
}
