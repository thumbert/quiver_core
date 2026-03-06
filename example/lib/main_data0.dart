import 'package:flutter/material.dart';
import 'package:graphic/graphic.dart' as g;
import 'package:timezone/data/latest.dart';
import 'chart_lite/chart_lite.dart';
import 'package:collection/collection.dart';

void main() {
  initializeTimeZones();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
  List<ScatterTrace> traces = [
    ScatterTrace(x: [1, 2, 3, 4], y: [10, 15, 13, 17], mode: 'markers'),
    ScatterTrace(x: [2, 3, 4, 5], y: [16, 5, 11, 9], mode: 'lines'),
    ScatterTrace(x: [1, 2, 3, 4], y: [12, 9, 15, 12], mode: 'lines+markers'),
  ];
  Layout layout = Layout.getDefault();


  //
  late List<Map<String, dynamic>> data;
  late Map<String, g.Variable<Map<dynamic, dynamic>, dynamic>> variables;
  late List<g.Mark<g.Shape>> marks;

  @override
  void initState() {
    super.initState();
    data = makeData(traces);
    variables = makeVariables(data);
    marks = makeMarks(traces);
  }

  List<Map<String, dynamic>> makeData(List<ScatterTrace> traces) {
    final data = <Map<String, dynamic>>[];
    for (var i = 0; i < traces.length; i++) {
      final trace = traces[i];
      for (var j = 0; j < trace.x.length; j++) {
        data.add({
          'x': trace.x[j],
          'y': trace.y[j],
          'name': trace.name ?? 'trace $i',
        });
      }
    }
    return data;
  }

  Map<String, g.Variable<Map<dynamic, dynamic>, dynamic>> makeVariables(
    List<Map<String, dynamic>> data,
  ) {
    return <String, g.Variable<Map<dynamic, dynamic>, dynamic>>{
      'x': g.Variable(accessor: (Map map) => map['x'] as int),
      'y': g.Variable(accessor: (Map map) => map['y'] as int),
      'name': g.Variable(accessor: (Map map) => map['name'] as String),
    };
  }

  /// Check the mode of each trace and return the appropriate marks.
  ///
  List<g.Mark<g.Shape>> makeMarks(List<ScatterTrace> traces) {
    return [
      g.LineMark(
        position: g.Varset('x') * g.Varset('y') / g.Varset('name'),
        color: g.ColorEncode(
          encoder: (e) {
            if (e['name'] == 'trace 1') {
              return Defaults.colors[1];
            } else if (e['name'] == 'trace 2') {
              return Defaults.colors[2];
            } else {
              return Colors.transparent;
            }
          },
        ),
      ),
      g.PointMark(
        color: g.ColorEncode(variable: 'name', values: Defaults.colors),
        size: g.SizeEncode(
          encoder: (e) {
            if (e['name'] == 'trace 0' || e['name'] == 'trace 2') {
              return 6.0;
            } else {
              return 0.0;
            }
          },
        ),
      ),
    ];
  }

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
            Container(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SizedBox(
                    height: 500,
                    child: g.Chart(
                      padding: (_) => const EdgeInsets.fromLTRB(40, 5, 80, 40),
                      data: data,
                      variables: variables,
                      marks: marks,
                      coord: g.RectCoord(
                        horizontalRange: [0, 1],
                        verticalRange: [0, 1],
                      ),
                      axes: [
                        g.AxisGuide(
                          grid: g.Defaults.strokeStyle,
                          label: g.LabelStyle(
                            textStyle: Defaults.textStyle.copyWith(
                              color: Colors.black,
                            ),
                            offset: const Offset(0, 7.5),
                          ),
                        ),
                        g.AxisGuide(
                          grid: g.Defaults.strokeStyle,
                          label: g.LabelStyle(
                            textStyle: Defaults.textStyle.copyWith(
                              color: Colors.black,
                            ),
                            offset: const Offset(-7.5, 0),
                          ),
                        ),
                      ],
                      selections: {
                        // 'choose': IntervalSelection(),
                        'touchMove': g.PointSelection(
                          on: {
                            g.GestureType.tapDown,
                            // GestureType.scaleEnd,
                            // GestureType.longPressMoveUpdate,
                          },
                          dim: g.Dim.x,
                        ),
                        'zoom': g.IntervalSelection(dim: g.Dim.x),
                      },
                      tooltip: g.TooltipGuide(
                        followPointer: [false, true],
                        align: Alignment.topLeft,
                        offset: const Offset(-20, -20),
                      ),
                      // crosshair: CrosshairGuide(
                      //   followPointer: [false, false],
                      // ),
                      annotations: makeAnnotations(traces, layout),
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

  // For legend
  List<g.Annotation>? makeAnnotations(List<ScatterTrace> traces, Layout layout) {
    if (traces.length == 1 || layout.showLegend == false) {
      return null;
    }
    var out = <g.Annotation>[];
    final maxLabelWidth = 80;

    for (var i = 0; i < traces.length; i++) {
      final trace = traces[i];
      final label = trace.name ?? 'trace $i';
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(fontSize: 14, color: Color(0xff000000)),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      // TODO: replace the 20 below with the right height of the text + gap!
      final dy = 20.0 + (i - 1) * 20.0 + tp.height / 2;
      final mode = trace.mode!;

      if (mode.contains('markers')) {
        out.add(
          g.CustomAnnotation(
            renderer: (_, size) => [
              g.CircleElement(
                center: Offset(size.width - maxLabelWidth, dy),
                radius: 3,
                style: g.PaintStyle(fillColor: Defaults.colors[i]),
              ),
            ],
            anchor: (p0) => Offset(0, 0),
          ),
        );
      }
      if (mode.contains('lines')) {
        out.add(
          g.CustomAnnotation(
            renderer: (_, size) => [
              g.LineElement(
                start: Offset(size.width - maxLabelWidth - 16, dy),
                end: Offset(size.width - maxLabelWidth + 16, dy),
                style: g.PaintStyle(strokeColor: Defaults.colors[i]),
              ),
            ],
            anchor: (p0) => Offset(0, 0),
          ),
        );
      }

      out.add(
        g.TagAnnotation(
          label: g.Label(
            label,
            g.LabelStyle(
              textStyle: const TextStyle(
                color: Color(0xff000000),
                fontSize: 14,
              ),
              align: Alignment.centerLeft, // anchor at left edge of text
            ),
          ),
          clip: false,
          anchor: (Size size) {
            final double gap = 8.0; // px gap between marker and label
            final double regionRight = size.width - 20.0;
            // place the left edge of text just outside plot by `gap`
            final dx = regionRight + gap;
            // compute vertical pos (example: centered vertically in chart)
            // final dy = size.height / 2 - tp.height / 2;
            // final dy = 20.0 + (i - 1) * 20.0 + tp.height / 2;
            return Offset(dx, dy);
          },
        ),
      );
    }
    return out;

    // // measure text width exactly like LabelElement does
    // final tps = _buildTextPainters(
    //   traces.mapIndexed((i, e) => e.name ?? 'trace $i').toList(),
    // );

    // final tp = TextPainter(
    //   text: TextSpan(
    //     text: 'trace 0',
    //     style: const TextStyle(fontSize: 14, color: Color(0xff000000)),
    //   ),
    //   textDirection: TextDirection.ltr,
    // )..layout();

    // return [
    //   g.CustomAnnotation(
    //     renderer: (_, size) => [
    //       g.CircleElement(
    //         center: Offset(size.width - 80, tp.height / 2),
    //         radius: 3,
    //         style: g.PaintStyle(fillColor: Defaults.colors[0]),
    //       ),
    //     ],
    //     anchor: (p0) => const Offset(0, 0),
    //   ),
    //   g.TagAnnotation(
    //     label: g.Label(
    //       'trace 0',
    //       g.LabelStyle(
    //         textStyle: const TextStyle(color: Color(0xff000000), fontSize: 14),
    //         align: Alignment.centerLeft, // anchor at left edge of text
    //       ),
    //     ),
    //     clip: false,
    //     anchor: (Size size) {
    //       final double gap = 8.0; // px gap from plot edge
    //       final double regionRight = size.width - 20.0;
    //       // place the left edge of text just outside plot by `gap`
    //       final dx = regionRight + gap;
    //       // compute vertical pos (example: centered vertically in chart)
    //       // final dy = size.height / 2 - tp.height / 2;
    //       final dy = tp.height / 2;
    //       return Offset(dx, dy);
    //     },
    //   ),
    // ];
  }
}
