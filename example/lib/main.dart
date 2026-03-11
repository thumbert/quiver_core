import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:quiver_core/quiver_core.dart';
import 'package:timezone/data/latest.dart';
import 'model/lmp.dart';

void main() {
  initializeTimeZones();
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
  void initState() {
    locations.value; // trigger loading of locations for Caiso
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),

      body: Center(
        child: Watch(
          (context) => Column(
            mainAxisAlignment: .start,
            children: [
              Container(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      spacing: 24.0,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16.0),
                          color: Colors.amber.shade100,
                          child: Column(
                            spacing: 12.0,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  SizedBox(width: 100, child: Text('Region')),
                                ],
                              ),
                              Row(
                                children: [
                                  SizedBox(width: 100, child: Text('Bucket')),
                                ],
                              ),
                              Row(
                                children: [
                                  SizedBox(
                                    width: 100,
                                    child: Text('Locations'),
                                  ),
                                  Container(
                                    width: 400,
                                    decoration: BoxDecoration(
                                      color: Colors.blueGrey.shade50,
                                      border: BoxBorder.all(
                                        color: Colors.blueGrey.shade200,
                                      ),
                                      borderRadius: BorderRadius.circular(4.0),
                                    ),
                                    child: MultiSelectAutocompleteUi(
                                      choices: cacheLocations.toSet(),
                                      selections:
                                          multipleLocations, // ListSignal<String>
                                      width: 400,
                                      height: 600,
                                      itemName: 'location',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        Container(
                          width: 400,
                          decoration: BoxDecoration(
                            color: Colors.blueGrey.shade50,
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          child: switch (locations.value) {
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
                        IconButton(
                          onPressed: () {
                            locationName.value = '';
                          },
                          icon: const Icon(Icons.clear),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
