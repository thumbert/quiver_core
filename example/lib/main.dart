import 'dart:async';

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
  final GlobalKey _chartKey = GlobalKey();
  final StreamController<GestureEvent> _gestureController =
      StreamController<GestureEvent>.broadcast();
  StreamSubscription<GestureEvent>? _gestureSub;
  Offset? _dragStart;
  List<Map<String, Object>> _filteredData = [];
  List<double>? _currentSelectionNormalized;

  @override
  void initState() {
    super.initState();
    _gestureSub = _gestureController.stream.listen((event) {
      try {
        final ge = event as GestureEvent;
        final g = ge.gesture;

        if (g.type == GestureType.scaleStart) {
          final details = g.details as ScaleStartDetails;
          final chartBox =
              _chartKey.currentContext?.findRenderObject() as RenderBox?;
          if (chartBox == null) return;
          // store local chart coordinates for the drag start
          _dragStart = chartBox.globalToLocal(details.focalPoint);
          // start live selection
          setState(() {
            _currentSelectionNormalized = null;
          });
        } else if (g.type == GestureType.scaleUpdate && _dragStart != null) {
          // live update of selection while dragging
          final chartBox =
              _chartKey.currentContext?.findRenderObject() as RenderBox?;
          if (chartBox == null) return;
          final localEnd = g.localPosition;
          const leftPad = 40.0;
          const rightPad = 10.0;
          final localStart = _dragStart!;
          final left = localStart.dx < localEnd.dx
              ? localStart.dx
              : localEnd.dx;
          final right = localStart.dx < localEnd.dx
              ? localEnd.dx
              : localStart.dx;
          final width = chartBox.size.width - leftPad - rightPad;
          if (width <= 0) return;
          double nx0 = ((left - leftPad) / width).clamp(0.0, 1.0);
          double nx1 = ((right - leftPad) / width).clamp(0.0, 1.0);
          if (nx1 <= nx0) return;
          setState(() {
            _currentSelectionNormalized = [nx0, nx1];
          });
        } else if (g.type == GestureType.scaleEnd && _dragStart != null) {
          final chartBox =
              _chartKey.currentContext?.findRenderObject() as RenderBox?;
          if (chartBox == null) return;

          // gesture.localPosition is already local to the chart
          final localEnd = g.localPosition;

          // Adjust these paddings to match your chart layout if needed.
          const leftPad = 40.0;
          const rightPad = 10.0;
          final localStart = _dragStart!;
          final left = localStart.dx < localEnd.dx
              ? localStart.dx
              : localEnd.dx;
          final right = localStart.dx < localEnd.dx
              ? localEnd.dx
              : localStart.dx;
          final width = chartBox.size.width - leftPad - rightPad;
          if (width <= 0) return;

          double nx0 = ((left - leftPad) / width).clamp(0.0, 1.0);
          double nx1 = ((right - leftPad) / width).clamp(0.0, 1.0);
          if (nx1 <= nx0) return;

          final all = prices.value.requireValue;
          final firstMs = all.first.$1.millisecondsSinceEpoch.toDouble();
          final lastMs = all.last.$1.millisecondsSinceEpoch.toDouble();
          final selMin = firstMs + nx0 * (lastMs - firstMs);
          final selMax = firstMs + nx1 * (lastMs - firstMs);

          setState(() {
            _filteredData = all
                .where((e) {
                  final t = (e.$1).millisecondsSinceEpoch.toDouble();
                  return t >= selMin && t <= selMax;
                })
                .map((e) => {'time': e.$1, 'price': e.$2})
                .toList();
            // clear live selection overlay once selection is committed
            _currentSelectionNormalized = null;
          });

          _dragStart = null;
        } else if (g.type == GestureType.doubleTap) {
          setState(() {
            _filteredData = [];
            _currentSelectionNormalized = null;
          });
        }
      } catch (err) {
        // swallow any cast errors or runtime hiccups during gesture handling
      }
    });
  }

  @override
  void dispose() {
    _gestureSub?.cancel();
    _gestureController.close();
    super.dispose();
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
                        AsyncData<List<(TZDateTime, num)>>() => Builder(
                          builder: (ctx) {
                            final fullMapped = prices.value.requireValue
                                .map((e) => {'time': e.$1, 'price': e.$2})
                                .toList();
                            return LayoutBuilder(
                              builder: (ctx2, constraints) {
                                final containerWidth = constraints.maxWidth;
                                const leftPad = 40.0;
                                const rightPad = 10.0;
                                final usableWidth =
                                    (containerWidth - leftPad - rightPad).clamp(
                                      0.0,
                                      double.infinity,
                                    );

                                return Container(
                                  key: _chartKey,
                                  child: Stack(
                                    children: [
                                      Chart(
                                        data: _filteredData.isNotEmpty
                                            ? _filteredData
                                            : fullMapped,
                                        variables: {
                                          'time': Variable(
                                            accessor: (Map map) =>
                                                map['time'] as TZDateTime,
                                          ),
                                          'price': Variable(
                                            accessor: (Map map) =>
                                                map['price'] as num,
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
                                        ),
                                        axes: [
                                          AxisGuide(
                                            grid: Defaults.strokeStyle,
                                            label: LabelStyle(
                                              textStyle:
                                                  lite.Defaults.textStyle,
                                              offset: const Offset(0, 7.5),
                                            ),
                                          ),
                                          AxisGuide(
                                            grid: Defaults.strokeStyle,
                                            label: LabelStyle(
                                              textStyle:
                                                  lite.Defaults.textStyle,
                                              offset: const Offset(-7.5, 0),
                                            ),
                                          ),
                                          AxisGuide(
                                            dim: Dim.y,
                                            position: 1,
                                            line: Defaults.strokeStyle,
                                            label: LabelStyle(
                                              textStyle:
                                                  lite.Defaults.textStyle,
                                              offset: const Offset(7.5, 0),
                                            ),
                                          ),
                                        ],
                                        selections: {
                                          'touchMove': PointSelection(
                                            on: {GestureType.tapDown},
                                            dim: Dim.x,
                                          ),
                                        },
                                        tooltip: TooltipGuide(
                                          followPointer: [false, true],
                                          align: Alignment.topLeft,
                                          offset: const Offset(-20, -20),
                                        ),
                                        crosshair: CrosshairGuide(
                                          followPointer: [false, false],
                                        ),
                                        gestureStream: _gestureController,
                                      ),

                                      if (_currentSelectionNormalized != null)
                                        Positioned(
                                          left:
                                              leftPad +
                                              _currentSelectionNormalized![0] *
                                                  usableWidth,
                                          top: 0,
                                          bottom: 0,
                                          width:
                                              (_currentSelectionNormalized![1] -
                                                  _currentSelectionNormalized![0]) *
                                              usableWidth,
                                          child: IgnorePointer(
                                            child: Container(
                                              color: Colors.grey.withAlpha(64),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
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
