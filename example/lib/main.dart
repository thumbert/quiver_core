import 'package:elec/elec.dart';
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
    model; // initialize the model and its effects!
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
        child: SignalBuilder(
          builder: (context) => Column(
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [Lmp(), TermsDemo()],
                    ),
                    Text(
                      'Selected locations: ${Model.locations.value.join(', ')}',
                    ),
                    Text('Selected location: ${Model.location.value}'),
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

class TermsDemo extends StatelessWidget {
  const TermsDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.greenAccent.shade100,
      child: Column(
        spacing: 12.0,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(width: 100, child: Text('Term')),
              Container(
                width: 200,
                decoration: BoxDecoration(
                  color: Colors.blueGrey.shade50,
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: TermUi(
                  model: term,
                  setTerm: (value) => term.value = value,
                  getTerm: (model) => term.value,
                  allowNull: true,
                ),
              ),
            ],
          ),
          Row(
            children: [
              SizedBox(width: 100, child: Text('Month')),
              Container(
                width: 200,
                decoration: BoxDecoration(
                  color: Colors.blueGrey.shade50,
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: MonthUi(
                  model: month,
                  setMonth: (value) => month.value = value,
                  getMonth: (model) => month.value,
                  allowNull: true,
                ),
              ),
            ],
          ),

          Row(
            children: [
              SizedBox(width: 100, child: Text('As of date')),
              Container(
                width: 200,
                decoration: BoxDecoration(
                  color: Colors.blueGrey.shade50,
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: DateUi(
                  model: day,
                  setDate: (value) => day.value = value,
                  getDate: (model) => day.value,
                  allowNull: true,
                ),
              ),
            ],
          ),

          /// select multiple months
          Row(
            children: [
              SizedBox(width: 120, child: Text('Pick months')),
              Container(
                width: 180,
                decoration: BoxDecoration(
                  color: Colors.blueGrey.shade50,
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: MultiSelectAutocompleteUi(
                  model: months,
                  setSelection: (value) => months.value = [...value],
                  getSelection: (model) => months.value,
                  choices: allMonths.toSet(),
                  hintTextBuilder: () {
                    final count = months.value.length;
                    if (count == 0) return '(None)';
                    if (count == 12) return '(All)';
                    return '$count month${count == 1 ? '' : 's'} selected';
                  },
                  width: 180,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class Lmp extends StatelessWidget {
  const Lmp({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
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
                  setSelection: (value) => Model.region.value = value,
                  getSelection: (model) => Model.region.value,
                  choices: {'CAISO', 'ISONE', 'NYISO'},
                  width: 200,
                  // padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 0.0),
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
                      Model.bucket.value = Bucket.parse(value),
                  getSelection: (model) => Model.bucket.value?.name ?? '',
                  choices: model
                      .getBuckets(Model.region.value)
                      .map((e) => e.name)
                      .toSet(),
                  width: 200,
                ),
              ),
            ],
          ),
          LocationsRow(),
          LocationRow(),
        ],
      ),
    );
  }
}

class LocationsRow extends StatelessWidget {
  const LocationsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(
      builder: (_) => Row(
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
                hintTextBuilder: () =>
                    '${Model.locations.value.length} location${Model.locations.value.length == 1 ? '' : 's'} selected',
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

class LocationRow extends StatelessWidget {
  const LocationRow({super.key});

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(
      builder: (_) => Row(
        children: [
          SizedBox(width: 100, child: Text('Location')),
          Container(
            width: 400,
            decoration: BoxDecoration(
              color: Colors.blueGrey.shade50,
              borderRadius: BorderRadius.circular(4.0),
            ),
            child: switch (Model.allLocations.value) {
              AsyncData<List<String>>() => AutocompleteUi(
                model: Model.location,
                setSelection: (value) => Model.location.value = value,
                getSelection: (model) => Model.location.value,
                clearSelection: () => Model.location.value = null,
                choices: Model.locationCache[Model.region.value]?.toSet() ?? {},
                width: 400,
                style: const TextStyle(fontSize: 14),
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
