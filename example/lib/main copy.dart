import 'package:flutter/material.dart';
import 'package:graphic/graphic.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:quiver_core/quiver_core.dart';
import 'package:timezone/data/latest.dart';
import 'package:timezone/timezone.dart';
import 'model/lmp.dart';
import 'chart_lite/chart_lite.dart' as lite;

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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Watch(
          (context) => Column(
            mainAxisAlignment: .center,
            children: [
              Container(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // const Text('Selection with search'),
                    Row(
                      children: [
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
                    SizedBox(
                      height: 500,
                      child: switch (prices.value) {
                        AsyncData<List<(TZDateTime, num)>>() => Chart(
                          data: prices.value.requireValue
                              .map((e) => {'time': e.$1, 'price': e.$2})
                              .toList(),
                          variables: {
                            'time': Variable(
                              accessor: (Map map) => map['time'] as TZDateTime,
                            ),
                            'price': Variable(
                              accessor: (Map map) => map['price'] as num,
                            ),
                          },
                          marks: [
                            LineMark(
                              color: ColorEncode(
                                value: lite.Defaults.colors[0],
                              ),
                            ),
                            PointMark(
                              color: ColorEncode(
                                value: lite.Defaults.colors[0],
                              ),
                            ),
                          ],
                          coord: RectCoord(
                            horizontalRange: [0, 1],
                            verticalRange: [0, 1],
                            horizontalRangeUpdater:
                                lite.Defaults.horizontalRangeEvent,
                            verticalRangeUpdater:
                                lite.Defaults.verticalRangeEvent,
                          ),
                          axes: [
                            AxisGuide(
                              grid: Defaults.strokeStyle,
                              label: LabelStyle(
                                textStyle: lite.Defaults.textStyle,
                                offset: const Offset(0, 7.5),
                              ),
                            ),
                            AxisGuide(
                              grid: Defaults.strokeStyle,
                              label: LabelStyle(
                                textStyle: lite.Defaults.textStyle,
                                offset: const Offset(-7.5, 0),
                              ),
                            ),
                            AxisGuide(
                              dim: Dim.y,
                              position: 1,
                              line: Defaults.strokeStyle,
                              label: LabelStyle(
                                textStyle: lite.Defaults.textStyle,
                                offset: const Offset(7.5, 0),
                              ),
                            ),
                          ],
                          selections: {
                            // 'choose': IntervalSelection(),
                            'touchMove': PointSelection(
                              on: {
                                GestureType.tapDown,
                                // GestureType.scaleEnd,
                                // GestureType.longPressMoveUpdate,
                              },
                              dim: Dim.x,
                            ),
                            'zoom': IntervalSelection(dim: Dim.x),
                          },
                          tooltip: TooltipGuide(
                            followPointer: [false, true],
                            align: Alignment.topLeft,
                            offset: const Offset(-20, -20),
                          ),
                          crosshair: CrosshairGuide(
                            followPointer: [false, false],
                          ),
                        ),
                        AsyncError<List<(TZDateTime, num)>>() => Text(
                          'Error loading traces',
                        ),
                        AsyncLoading<List<(TZDateTime, num)>>() => Center(
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      },
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
