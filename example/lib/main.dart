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
    // locations.value; // trigger loading of locations for Caiso
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
                  spacing: 24.0,
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
                                  Container(
                                    width: 200,
                                    decoration: BoxDecoration(
                                      color: Colors.blueGrey.shade50,
                                      borderRadius: BorderRadius.circular(4.0),
                                    ),
                                    child: DropdownUi(
                                      model: Model.region,
                                      setSelection: (value) =>
                                          Model.region.value = value,
                                      getSelection: (model) =>
                                          Model.region.value,
                                      choices: {'CAISO', 'ISONE', 'NYISO'},
                                      width: 200,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  SizedBox(width: 100, child: Text('Bucket')),
                                  Container(
                                    width: 200,
                                    decoration: BoxDecoration(
                                      color: Colors.blueGrey.shade50,
                                      borderRadius: BorderRadius.circular(4.0),
                                    ),
                                    child: DropdownUi(
                                      model: Model.bucket,
                                      setSelection: (value) =>
                                          Model.bucket.value = value,
                                      getSelection: (model) =>
                                          Model.bucket.value,
                                      choices: model.getBuckets(
                                        Model.region.value,
                                      ),
                                      width: 200,
                                    ),
                                  ),
                                ],
                              ),
                              LocationRow(),
                            ],
                          ),
                        ),

                        // Container(
                        //   width: 400,
                        //   decoration: BoxDecoration(
                        //     color: Colors.blueGrey.shade50,
                        //     borderRadius: BorderRadius.circular(4.0),
                        //   ),
                        //   child: switch (locations.value) {
                        //     AsyncData<List<String>>() => AutocompleteUi(
                        //       model: locationName,
                        //       choices: Model.locationCache[Model.region.value]?.toSet() ?? {},
                        //       setSelection: (value) =>
                        //           locationName.value = value,
                        //       getSelection: (model) => locationName.value,
                        //       width: 400,
                        //       key: ValueKey(
                        //         locationName.value,
                        //       ), // needed to wipe the textfield on icon clear
                        //     ),
                        //     AsyncError<List<String>>() => Text(
                        //       'Error loading locations for Caiso',
                        //     ),
                        //     AsyncLoading<List<String>>() => Center(
                        //       child: CircularProgressIndicator(),
                        //     ),
                        //   },
                        // ),
                        // IconButton(
                        //   onPressed: () {
                        //     locationName.value = '';
                        //   },
                        //   icon: const Icon(Icons.clear),
                        // ),
                      ],
                    ),

                    Text(
                      'Selected locations: ${Model.locations.value.join(', ')}',
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

class LocationRow extends StatelessWidget {
  const LocationRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Watch(
      (_) => Row(
        children: [
          SizedBox(width: 100, child: Text('Locations')),
          Container(
            width: 400,
            decoration: BoxDecoration(
              color: Colors.blueGrey.shade50,
              borderRadius: BorderRadius.circular(4.0),
            ),
            child: switch (Model.allLocations.value) {
              AsyncData<List<String>>() => MultiSelectAutocompleteUi(
                model: Model.locations,
                setSelection: (value) => Model.locations.value = [...value],
                getSelection: (model) => Model.locations.value,
                choices: Model.locationCache[Model.region.value]?.toSet() ?? {},
                itemName: 'location',
                width: 400,
              ),
              AsyncError<List<String>>() => Text(
                'Error loading locations for ${Model.region.value}',
              ),
              AsyncLoading<List<String>>() => Center(
                child: CircularProgressIndicator(),
              ),
            },
          ),
        ],
      ),
    );
  }
}
