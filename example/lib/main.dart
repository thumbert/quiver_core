import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:signals_flutter/signals_flutter.dart';
import 'package:quiver_core/quiver_core.dart';

final locationName = signal('TH_NP15_GEN-APND', debugLabel: 'locationName');
final locations = futureSignal(getLocations, debugLabel: 'locations');
final cacheLocations = <String>['TH_NP15_GEN-APND'];

Future<List<String>> getLocations() async {
  if (cacheLocations.length == 1) {
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

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  static const String rustServer = 'http://127.0.0.1:8111';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quiver Core Gallery',
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
      home: const MyHomePage(title: 'Quiver Core Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: .center,
          children: [
            SizedBox(
              width: 600,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text('Selection with search'),
                  Row(
                    children: [
                      Container(
                        width: 400,
                        decoration: BoxDecoration(
                          color: Colors.blueGrey.shade50,
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        child: Watch(
                          (_) => switch (locations.value) {
                            AsyncData<List<String>>() => AutocompleteUi(
                              model: locationName,
                              choices: cacheLocations.toSet(),
                              setSelection: (value) =>
                                  locationName.value = value,
                              getSelection: (model) => locationName.value,
                              width: 400,
                              key: ValueKey(
                                locationName.value,
                              ), // needed to wipe the textfield on icon clear
                            ),
                            AsyncError<List<String>>() => Text(
                              'Error loading locations for Caiso',
                            ),
                            AsyncLoading<List<String>>() => Center(
                              child: CircularProgressIndicator(),
                            ),
                          },
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          locationName.value = '';
                          // setState(() {}); // need to force a build
                        },
                        icon: const Icon(Icons.clear),
                      ),
                    ],
                  ),
                  const SizedBox(height: 500),
                  Watch(
                    (context) => Text(
                      'Currently selected location: ${locationName.value}',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
