import 'package:flutter/material.dart';
import 'package:gallery/assets/data.dart';
import 'package:graphic/graphic.dart';
import 'package:timezone/data/latest.dart';
import 'chart_lite/chart_lite.dart' as lite;

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
                    child: Chart(
                      padding: (_) => const EdgeInsets.fromLTRB(40, 5, 80, 40),
                      data: data0,
                      variables: {
                        'x': Variable(accessor: (Map map) => map['x'] as int),
                        'y': Variable(accessor: (Map map) => map['y'] as int),
                        'label': Variable(
                          accessor: (Map map) => map['label'] as String,
                        ),
                      },
                      marks: [
                        LineMark(
                          position: Varset('x') * Varset('y') / Varset('label'),
                          color: ColorEncode(
                            encoder: (e) {
                              if (e['label'] == 'B') {
                                return lite.Defaults.colors[1];
                              } else if (e['label'] == 'C') {
                                return lite.Defaults.colors[2];
                              } else {
                                return Colors.transparent;
                              }
                            },
                          ),
                        ),
                        PointMark(
                          color: ColorEncode(
                            variable: 'label',
                            values: lite.Defaults.colors,
                          ),
                          size: SizeEncode(
                            encoder: (e) {
                              if (e['label'] == 'A' || e['label'] == 'C') {
                                return 6.0;
                              } else {
                                return 0.0;
                              }
                            },
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
                            textStyle: lite.Defaults.textStyle.copyWith(
                              color: Colors.black,
                            ),
                            offset: const Offset(0, 7.5),
                          ),
                        ),
                        AxisGuide(
                          grid: Defaults.strokeStyle,
                          label: LabelStyle(
                            textStyle: lite.Defaults.textStyle.copyWith(
                              color: Colors.black,
                            ),
                            offset: const Offset(-7.5, 0),
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
                      // crosshair: CrosshairGuide(
                      //   followPointer: [false, false],
                      // ),
                      annotations: _buildAnnotations(),
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

  List<TextPainter> _buildTextPainters(List<String> labels) {
    final tps = labels
        .map(
          (e) => TextPainter(
            text: TextSpan(
              text: e,
              style: const TextStyle(fontSize: 14, color: Color(0xff000000)),
            ),
            textDirection: TextDirection.ltr,
          )..layout(),
        )
        .toList();
    return tps;
  }

  List<Annotation> _buildAnnotations() {
    // measure text width exactly like LabelElement does
    final tp = TextPainter(
      text: TextSpan(
        text: 'trace 0',
        style: const TextStyle(fontSize: 14, color: Color(0xff000000)),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    return [
      CustomAnnotation(
        renderer: (_, size) => [
          CircleElement(
            center: Offset(size.width - 80, tp.height / 2),
            radius: 3,
            style: PaintStyle(fillColor: lite.Defaults.colors[0]),
          ),
        ],
        anchor: (p0) => const Offset(0, 0),
      ),
      TagAnnotation(
        label: Label(
          'trace 0',
          LabelStyle(
            textStyle: const TextStyle(color: Color(0xff000000), fontSize: 14),
            align: Alignment.centerLeft, // anchor at left edge of text
          ),
        ),
        clip: false,
        anchor: (Size size) {
          final double gap = 8.0; // px gap from plot edge
          final double regionRight = size.width - 20.0;
          // place the left edge of text just outside plot by `gap`
          final dx = regionRight + gap;
          // compute vertical pos (example: centered vertically in chart)
          // final dy = size.height / 2 - tp.height / 2;
          final dy = tp.height / 2;
          return Offset(dx, dy);
        },
      ),
    ];
  }
}
