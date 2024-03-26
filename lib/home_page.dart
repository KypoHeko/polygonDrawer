import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'main.dart';

class DottedPaper extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Color color = Colors.blue.shade200;
    List<Offset> dots = [];

    var paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.5;

    for (double x = 0.0; x <= size.width; x += 25.0) {
      for (double y = 0.0; y <= size.height; y += 25.0) {
        dots.add(Offset(x, y));
      }
    }

    canvas.drawPoints(PointMode.points, dots, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class DrawLine extends CustomPainter {
  final Offset point1;
  final Offset point2;

  DrawLine({
    required this.point1,
    required this.point2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const Color color = Colors.black;
    final Offset distanceOffset = point2 - point1;
    final String distance = (distanceOffset.distance.round() / 100).toString();
    final double direction = (point2 - point1).direction;

    var paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 7;

    canvas.drawLine(Offset.zero, distanceOffset, paint);

    canvas.rotate(direction);
    canvas.save();

    final TextSpan span = TextSpan(
      text: distance,
      style: const TextStyle(
        color: Colors.blue,
        fontSize: 16,
      ),
    );

    var textPainter = TextPainter()
      ..text = span
      ..textDirection = TextDirection.ltr
      ..layout(minWidth: 0, maxWidth: double.maxFinite);

    textPainter.paint(
        canvas, Offset((distanceOffset.dy + distanceOffset.dx).abs() / 3, -25));

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class FillPolygon extends CustomPainter {
  final List<Offset> points;

  FillPolygon({super.repaint, required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    const Color color = Colors.white;

    var paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.square
      ..strokeWidth = 3;

    var path = Path();

    path.moveTo(points.last.dx, points.last.dy);
    for (Offset point in points) {
      path.lineTo(point.dx, point.dy);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class MyHomePage extends ConsumerWidget {
  Offset listenerOffset = Offset.zero;
  Offset previousOffset = Offset.zero;

  final double radius = 10;

  MyHomePage({super.key});

  Widget singlePoint(ref) {
    bool isPolygon = ref.read(isPolygonSP);

    final Color generalColor = isPolygon ? Colors.white : Colors.blue;
    final Color borderColor = isPolygon ? Colors.grey : Colors.white;

    return Container(
      width: radius,
      height: radius,
      decoration: BoxDecoration(
        border: Border.all(
          color: borderColor,
          width: 1.5,
        ),
        color: generalColor,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget buttonsUndoRedo(ref) {
    List<Offset> points = ref.read(pointsSP);
    List<Offset> redos = ref.read(redosSP);

    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: points.isEmpty
                ? null
                : () {
                    undo(ref);
                  },
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.undo),
          ),
          Container(
            width: 1,
            height: 16,
            color: Colors.grey,
          ),
          IconButton(
            onPressed: redos.isEmpty
                ? null
                : () {
                    redo(ref);
                  },
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.redo),
          )
        ],
      ),
    );
  }

  Widget buttonAttractedGrid(ref) {
    bool isAttracted = ref.read(isAttractedSP);

    return ElevatedButton(
      onPressed: () {
        isAttracted = !isAttracted;
        if (isAttracted) attractToGrid(ref);
        ref.read(isAttractedSP.notifier).update((state) => isAttracted);
      },
      style: ElevatedButton.styleFrom(
        shape: const CircleBorder(),
        padding: const EdgeInsets.all(8),
        backgroundColor: Colors.white,
        elevation: 5,
      ),
      child: Icon(
        Icons.grid_3x3,
        size: 36,
        color: isAttracted ? Colors.black : Colors.grey,
      ),
    );
  }

  void isPointNearby(ref) {
    List<Offset> points = ref.read(pointsSP);
    List<Offset> redos = ref.read(redosSP);
    bool isPolygon = ref.read(isPolygonSP);

    if (points.length < 3) return;

    final double distance = (points.last - points.first).distance;
    if (distance < 20) {
      redos.clear();
      points.remove(points.last);
      isPolygon = true;

      ref.read(isPolygonSP.notifier).update((state) => isPolygon);
      ref.read(pointsSP.notifier).update((state) => [...points]);
      ref.read(redosSP.notifier).update((state) => [...redos]);
    }
  }

  void isIntersect(ref, bool isCreated) {
    List<Offset> points = ref.read(pointsSP);

    if (points.length < 4) return;

    Offset point1 = points[points.length - 1];
    Offset point2 = points[points.length - 2];

    for (int i = 0; i < points.length - 2; i++) {
      Offset point3 = points[i];
      Offset point4 = points[i + 1];

      List<List<double>> matrix = [
        [
          point2.dx - point1.dx,
          -(point4.dx - point3.dx),
          point3.dx - point1.dx
        ],
        [
          point2.dy - point1.dy,
          -(point4.dy - point3.dy),
          point3.dy - point1.dy
        ],
      ];

      // Если в матрице не содержится 0
      if (matrix[0][0] != 0 &&
          matrix[1][0] != 0 &&
          matrix[0][1] != 0 &&
          matrix[1][1] != 0) {
        double temp = matrix[0][0];

        // Домножаем обе строки на первые элементы
        matrix[0] = matrix[0].map((e) => e * matrix[1][0]).toList();
        matrix[1] = matrix[1].map((e) => e * temp).toList();

        // Приводим к треугольному виду
        for (int i = 0; i < matrix[1].length; i++) {
          matrix[1][i] = matrix[0][i] - matrix[1][i];
        }
      } else {
        // Если второй элемент одной из строк равен 0
        if (matrix[0][1] == 0 || matrix[1][1] == 0) {
          // Меняем местами столбцы
          double temp;

          temp = matrix[0][0];
          matrix[0][0] = matrix[0][1];
          matrix[0][1] = temp;

          temp = matrix[1][0];
          matrix[1][0] = matrix[1][1];
          matrix[1][1] = temp;
        }

        // Если первый элемент равен 0
        if (matrix[0][0] == 0) {
          // Меняем местами строки
          List<double> temp = matrix[0];
          matrix[0] = matrix[1];
          matrix[1] = temp;
        }
      }

      // Находим параметр t
      matrix[1] = matrix[1].map((e) => e / matrix[1][1]).toList();

      // Переносим в правую часть
      matrix[0][2] -= matrix[0][1] * matrix[1][2];
      matrix[0][1] = 0;

      // Находим параметр s
      matrix[0] = matrix[0].map((e) => e / matrix[0][0]).toList();

      double s = matrix[0][2];
      double t = matrix[1][2];

      if ((0 < s) & (s < 1) & (0 < t) & (t < 1)) {
        isCreated ? points.remove(points.last) : points.last = previousOffset;
      }
    }
  }

  void undo(ref) {
    List<Offset> points = ref.read(pointsSP);
    List<Offset> redos = ref.read(redosSP);
    bool isPolygon = ref.read(isPolygonSP);

    if (isPolygon) {
      isPolygon = false;
      redos.add(points.first);

      ref.read(isPolygonSP.notifier).update((state) => isPolygon);
      ref.read(redosSP.notifier).update((state) => [...redos]);

      return;
    }
    redos.add(points.last);
    points.remove(points.last);

    ref.read(pointsSP.notifier).update((state) => [...points]);
    ref.read(redosSP.notifier).update((state) => [...redos]);
  }

  void redo(ref) {
    List<Offset> points = ref.read(pointsSP);
    List<Offset> redos = ref.read(redosSP);
    bool isPolygon = ref.read(isPolygonSP);

    if (redos.last == points.first) {
      isPolygon = true;
      redos.remove(redos.last);
      
      ref.read(isPolygonSP.notifier).update((state) => isPolygon);
      ref.read(redosSP.notifier).update((state) => [...redos]);

      return;
    }
    points.add(redos.last);
    redos.remove(redos.last);

    ref.read(pointsSP.notifier).update((state) => [...points]);
    ref.read(redosSP.notifier).update((state) => [...redos]);
  }

  void attractToGrid(ref) {
    List<Offset> points = ref.read(pointsSP);

    for (int i = 0; i < points.length; i++) {
      Offset remainder = points[i] % 25;

      var x = remainder.dx;
      var y = remainder.dy;

      if (remainder.dx > 12.5) x -= 25;
      if (remainder.dy > 12.5) y -= 25;

      points[i] = points[i] - Offset(x, y);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Size size = MediaQuery.of(context).size;

    final points = ref.watch(pointsSP);
    final redos = ref.watch(redosSP);
    bool isPolygon = ref.watch(isPolygonSP);
    bool isAttracted = ref.watch(isAttractedSP);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        toolbarHeight: 0,
      ),
      backgroundColor: Colors.grey.shade300,
      body: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            painter: DottedPaper(),
          ),
          if (!isPolygon)
            GestureDetector(
              onPanDown: (details) {
                previousOffset = details.localPosition;
                points.add(details.localPosition);
                ref.read(pointsSP.notifier).update((state) => [...points]);
              },
              onPanUpdate: (details) {
                points.last = details.localPosition;
                ref.read(pointsSP.notifier).update((state) => [...points]);
              },
              onPanEnd: (details) {
                redos.clear();
                isPointNearby(ref);
                isIntersect(ref, true);
                if (isAttracted) attractToGrid(ref);
                ref.read(pointsSP.notifier).update((state) => [...points]);
              },
            ),
          if (isPolygon) ...{
            Positioned(
              child: CustomPaint(
                painter: FillPolygon(
                  points: points,
                ),
              ),
            ),
            Positioned(
              left: points.last.dx,
              top: points.last.dy,
              child: CustomPaint(
                painter: DrawLine(
                  point1: points.last,
                  point2: points.first,
                ),
              ),
            ),
          },
          for (int i = 0; i < points.length - 1; i++) ...[
            Positioned(
              left: points[i].dx,
              top: points[i].dy,
              child: CustomPaint(
                painter: DrawLine(
                  point1: points[i],
                  point2: points[i + 1],
                ),
              ),
            ),
          ],
          for (int i = 0; i < points.length; i++) ...[
            Positioned(
              left: points[i].dx - (radius / 2),
              top: points[i].dy - (radius / 2),
              child: Listener(
                onPointerDown: (listener) {
                  listenerOffset = listener.localPosition;
                },
                child: Draggable(
                  childWhenDragging: const SizedBox.shrink(),
                  feedback: singlePoint(ref),
                  onDragStarted: () {
                    previousOffset = points[i];
                  },
                  onDragUpdate: (details) {
                    double x = details.localPosition.dx -
                        listenerOffset.dx +
                        (radius / 2);
                    double y = details.localPosition.dy -
                        listenerOffset.dy +
                        (radius / 2) -
                        24;
                    points[i] = Offset(x, y);
                    ref.read(pointsSP.notifier).update((state) => [...points]);
                  },
                  onDragEnd: (details) {
                    if (!isPolygon) isPointNearby(ref);
                    isIntersect(ref, false);
                    if (isAttracted) attractToGrid(ref);
                    ref.read(pointsSP.notifier).update((state) => [...points]);
                  },
                  child: singlePoint(ref),
                ),
              ),
            ),
          ],
          Positioned(
            left: 10,
            top: 20,
            child: buttonsUndoRedo(ref),
          ),
          Positioned(
            left: size.width - 70,
            top: 10,
            child: buttonAttractedGrid(ref),
          )
        ],
      ),
    );
  }
}
