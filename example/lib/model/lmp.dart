import 'dart:convert';

import 'package:date/date.dart';
import 'package:gallery/main.dart';
import 'package:http/http.dart' as http;
import 'package:signals_flutter/signals_flutter.dart';
import 'package:timezone/timezone.dart';

typedef Bucket = String;

class Model {
  Model({required this.region, required this.locations, required this.bucket});

  final String region;
  final List<String> locations;
  final Bucket bucket;

  Model copyWith({String? region, List<String>? locations, Bucket? bucket}) {
    return Model(
      region: region ?? this.region,
      locations: locations ?? this.locations,
      bucket: bucket ?? this.bucket,
    );
  }
}

final locationName = signal('TH_NP15_GEN-APND', debugLabel: 'locationName');
final multipleLocations = ListSignal<String>(
  [],
  debugLabel: 'multipleLocations',
);

final locations = futureSignal(getLocations, debugLabel: 'locations');

final cacheLocations = <String>[];
Future<List<String>> getLocations() async {
  if (cacheLocations.isEmpty) {
    var xs = <String>[];
    var res = await http.get(
      Uri.parse('${MyApp.rustServer}/caiso/node_table/all'),
    );
    if (res.statusCode == 200) {
      var aux = (json.decode(res.body) as List).cast<Map<String, dynamic>>();
      xs.addAll(aux.map<String>((e) => e['name']));
      cacheLocations.addAll(xs);
    } else {
      throw Exception('Failed to load locations for Caiso');
    }
  }
  return cacheLocations;
}

final term = signal(
  Term.parse('Jan26', getLocation('America/Los_Angeles')),
  debugLabel: 'term',
);
final tz = getLocation('America/Los_Angeles');

final prices = futureSignal(
  () async {
    var data = await getHourlyLmpCaiso(
      locationName: locationName.value,
      term: term.value,
    );
    // print(data.length);
    return data;
  },
  debugLabel: 'prices',
  dependencies: [locationName, term],
);

Future<List<(TZDateTime, num)>> getHourlyLmpCaiso({
  required String locationName,
  required Term term,
}) async {
  final tz = getLocation('America/Los_Angeles');
  final url =
      '${MyApp.rustServer}/caiso/prices/da/hourly/'
      'start/${term.startDate.toString()}/end/${term.endDate.toString()}'
      '?node_ids=$locationName&components=lmp';
  print(url);
  var response = await http.get(Uri.parse(url));
  var data = json.decode(response.body) as List;
  print('Data length: ${data.length}');
  return data
      .map<(TZDateTime, num)>(
        (e) => (TZDateTime.parse(tz, e['hour_beginning']), e['price']),
      )
      .toList();
}
