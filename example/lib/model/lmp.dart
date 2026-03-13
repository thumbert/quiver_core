import 'dart:convert';

import 'package:date/date.dart';
import 'package:gallery/main.dart';
import 'package:http/http.dart' as http;
import 'package:signals_flutter/signals_flutter.dart';
import 'package:timezone/timezone.dart';

typedef Bucket = String;

final model = Model();

class Model {
  Model() {
    _regionEffect = effect(onUpdateRegion);
  }

  static final region = signal('CAISO', debugLabel: 'region');
  static final bucket = signal('Caiso6x16', debugLabel: 'bucket');
  static final locations = ListSignal(<String>[], debugLabel: 'locations');

  static final allLocations = futureSignal(
    getLocations,
    debugLabel: 'getAllLocations',
    dependencies: [region],
  );

  // ignore: unused_field
  late final void Function() _regionEffect;

  void onUpdateRegion() {
    bucket.value = getBuckets(region.value).first;
    locations.value = [];                                          // setSelection: (value) =>
                                          //     Model.locations.value = [
                                          //       ...value,
                                          //     ],
                                          // getSelection: (model) =>
                                          //     Model.locations.value,
                                          // setSelection: (value) =>
                                          //     Model.locations.value = [
                                          //       ...value,
                                          //     ],
                                          // getSelection: (model) =>
                                          //     Model.locations.value,

  }

  static final locationCache = <String, List<String>>{};

  static Future<List<String>> getLocations() async {
    final r = region.value;
    // print('in getLocations for $r, cached: ${locationCache.containsKey(r)}');
    if (!locationCache.containsKey(r)) {
      var res = await http.get(
        Uri.parse('${MyApp.rustServer}/${r.toLowerCase()}/node_table/all'),
      );
      if (res.statusCode == 200) {
        var aux = (json.decode(res.body) as List).cast<Map<String, dynamic>>();
        locationCache[r] = aux.map<String>((e) => e['name'] as String).toList();
      } else {
        throw Exception('Failed to load locations for $r');
      }
    }
    return locationCache[r]!;
  }

  Set<String> getBuckets(String region) {
    switch (region) {
      case 'CAISO':
        return {'Caiso6x16', 'Caiso1x16H', 'ATC'};
      case 'ISONE':
      case 'NYISO':
        return {'5x16', '2x16H', '7x8', 'ATC'};
      default:
        return {};
    }
  }
}

// final locationName = signal('TH_NP15_GEN-APND', debugLabel: 'locationName');
// final multipleLocations = ListSignal<String>(
//   [],
//   debugLabel: 'multipleLocations',
// );

// final locations = futureSignal(Model.getLocations, debugLabel: 'locations');

// final cacheLocations = <String>[];
// Future<List<String>> getLocations() async {
//   if (cacheLocations.isEmpty) {
//     var xs = <String>[];
//     var res = await http.get(
//       Uri.parse('${MyApp.rustServer}/caiso/node_table/all'),
//     );
//     if (res.statusCode == 200) {
//       var aux = (json.decode(res.body) as List).cast<Map<String, dynamic>>();
//       xs.addAll(aux.map<String>((e) => e['name']));
//       cacheLocations.addAll(xs);
//     } else {
//       throw Exception('Failed to load locations for Caiso');
//     }
//   }
//   return cacheLocations;
// }

final term = signal(
  Term.parse('Jan26', getLocation('America/Los_Angeles')),
  debugLabel: 'term',
);
final tz = getLocation('America/Los_Angeles');

final prices = futureSignal(
  () async {
    var data = await getHourlyLmpCaiso(
      locationName: Model.locations.value.first,
      term: term.value,
    );
    // print(data.length);
    return data;
  },
  debugLabel: 'prices',
  dependencies: [Model.locations, term],
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
