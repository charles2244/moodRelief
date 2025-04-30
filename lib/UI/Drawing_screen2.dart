import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_drawing_board/flutter_drawing_board.dart';
import 'package:flutter_drawing_board/paint_contents.dart';
import 'package:flutter_drawing_board/paint_extension.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/drawing_service.dart';
import 'test_data.dart';

Future<ui.Image> _getImage(String path) async {
  final Completer<ImageInfo> completer = Completer<ImageInfo>();
  final NetworkImage img = NetworkImage(path);
  img.resolve(ImageConfiguration.empty).addListener(
    ImageStreamListener((ImageInfo info, _) {
      completer.complete(info);
    }),
  );

  final ImageInfo imageInfo = await completer.future;

  return imageInfo.image;
}

const Map<String, dynamic> _testLine1 = <String, dynamic>{
  'type': 'StraightLine',
  'startPoint': <String, dynamic>{
    'dx': 68.94337550070736,
    'dy': 62.05980083656557
  },
  'endPoint': <String, dynamic>{
    'dx': 277.1373386828114,
    'dy': 277.32029957032194
  },
  'paint': <String, dynamic>{
    'blendMode': 3,
    'color': 4294198070,
    'filterQuality': 3,
    'invertColors': false,
    'isAntiAlias': false,
    'strokeCap': 1,
    'strokeJoin': 1,
    'strokeWidth': 4.0,
    'style': 1
  }
};

const Map<String, dynamic> _testLine2 = <String, dynamic>{
  'type': 'StraightLine',
  'startPoint': <String, dynamic>{
    'dx': 106.35164817830423,
    'dy': 255.9575653134524
  },
  'endPoint': <String, dynamic>{
    'dx': 292.76034659254094,
    'dy': 92.125586665872
  },
  'paint': <String, dynamic>{
    'blendMode': 3,
    'color': 4294198070,
    'filterQuality': 3,
    'invertColors': false,
    'isAntiAlias': false,
    'strokeCap': 1,
    'strokeJoin': 1,
    'strokeWidth': 4.0,
    'style': 1
  }
};

/// Custom drawn triangles
class Triangle extends PaintContent {
  Triangle();

  Triangle.data({
    required this.startPoint,
    required this.A,
    required this.B,
    required this.C,
    required Paint paint,
  }) : super.paint(paint);

  factory Triangle.fromJson(Map<String, dynamic> data) {
    return Triangle.data(
      startPoint: jsonToOffset(data['startPoint'] as Map<String, dynamic>),
      A: jsonToOffset(data['A'] as Map<String, dynamic>),
      B: jsonToOffset(data['B'] as Map<String, dynamic>),
      C: jsonToOffset(data['C'] as Map<String, dynamic>),
      paint: jsonToPaint(data['paint'] as Map<String, dynamic>),
    );
  }

  Offset startPoint = Offset.zero;

  Offset A = Offset.zero;
  Offset B = Offset.zero;
  Offset C = Offset.zero;

  @override
  String get contentType => 'Triangle';

  @override
  void startDraw(Offset startPoint) => this.startPoint = startPoint;

  @override
  void drawing(Offset nowPoint) {
    A = Offset(
        startPoint.dx + (nowPoint.dx - startPoint.dx) / 2, startPoint.dy);
    B = Offset(startPoint.dx, nowPoint.dy);
    C = nowPoint;
  }

  @override
  void draw(Canvas canvas, Size size, bool deeper) {
    final Path path = Path()
      ..moveTo(A.dx, A.dy)
      ..lineTo(B.dx, B.dy)
      ..lineTo(C.dx, C.dy)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  Triangle copy() => Triangle();

  @override
  Map<String, dynamic> toContentJson() {
    return <String, dynamic>{
      'startPoint': startPoint.toJson(),
      'A': A.toJson(),
      'B': B.toJson(),
      'C': C.toJson(),
      'paint': paint.toJson(),
    };
  }
}

/// Custom drawn image
/// url: https://web-strapi.mrmilu.com/uploads/flutter_logo_470e9f7491.png
const String _imageUrl =
    'https://web-strapi.mrmilu.com/uploads/flutter_logo_470e9f7491.png';

class ImageContent extends PaintContent {
  ImageContent(this.image, {this.imageUrl = ''});

  ImageContent.data({
    required this.startPoint,
    required this.size,
    required this.image,
    required this.imageUrl,
    required Paint paint,
  }) : super.paint(paint);

  factory ImageContent.fromJson(Map<String, dynamic> data) {
    return ImageContent.data(
      startPoint: jsonToOffset(data['startPoint'] as Map<String, dynamic>),
      size: jsonToOffset(data['size'] as Map<String, dynamic>),
      imageUrl: data['imageUrl'] as String,
      image: data['image'] as ui.Image,
      paint: jsonToPaint(data['paint'] as Map<String, dynamic>),
    );
  }

  Offset startPoint = Offset.zero;
  Offset size = Offset.zero;
  final String imageUrl;
  final ui.Image image;

  @override
  String get contentType => 'ImageContent';

  @override
  void startDraw(Offset startPoint) => this.startPoint = startPoint;

  @override
  void drawing(Offset nowPoint) => size = nowPoint - startPoint;

  @override
  void draw(Canvas canvas, Size size, bool deeper) {
    final Rect rect = Rect.fromPoints(startPoint, startPoint + this.size);
    paintImage(canvas: canvas, rect: rect, image: image, fit: BoxFit.fill);
  }

  @override
  ImageContent copy() => ImageContent(image);

  @override
  Map<String, dynamic> toContentJson() {
    return <String, dynamic>{
      'startPoint': startPoint.toJson(),
      'size': size.toJson(),
      'imageUrl': imageUrl,
      'paint': paint.toJson(),
    };
  }
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'New Drawing',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MyHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  /// 绘制控制器
  final DrawingController _drawingController = DrawingController();

  final TransformationController _transformationController =
  TransformationController();

  double _colorOpacity = 1;

  @override
  void dispose() {
    _drawingController.dispose();
    super.dispose();
  }


  /// 获取画板数据 `getImageData()`
  Future<void> _getImageData() async {
    final Uint8List? data = (await _drawingController.getImageData())?.buffer.asUint8List();
    if (data == null) {
      debugPrint('获取图片数据失败');
      return;
    }

    await _saveDrawingEntry(context, data);
  }

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final DrawingService _drawingService = DrawingService();

  Future<void> _saveDrawingEntry(BuildContext context, Uint8List imageBytes) async {
    final TextEditingController _titleInputController = TextEditingController();

    final prefs = await SharedPreferences.getInstance();
    final int? userId = prefs.getInt('user_id'); // Read the saved int user_id

    if (userId == null) {
      // Handle missing user ID gracefully
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User not logged in. Please log in again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Enter Drawing Title'),
          content: TextField(
            controller: _titleInputController,
            decoration: const InputDecoration(
              hintText: 'e.g., Sunset Landscape',
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.check, color: Colors.green),
              onPressed: () async {
                final title = _titleInputController.text.trim();
                if (title.isNotEmpty) {
                  //final base64Image = base64Encode(imageBytes);
                  await _drawingService.saveDrawing(
                    title: title,
                    imageData: imageBytes,
                    canvasSize: '500x800',
                    userId: userId, // Or get it dynamically
                  );
                  Navigator.of(context).pop();
                  Navigator.of(context).pop(true);
                  // Optionally, show a success message
                  showDialog(
                    context: context,
                    builder: (context) => Dialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      backgroundColor: const Color(0xFFFBF7EF), // Light cream background
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Bunny image centered
                            ClipRRect(
                              borderRadius: BorderRadius.circular(50),
                              child: SizedBox(
                                height: 120,
                                width: 120,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Image.asset(
                                      'assets/bunnyBackground.png',
                                      height: 120,
                                      width: 120,
                                      fit: BoxFit.cover,
                                    ),
                                    Image.asset(
                                      'assets/bunny.png',
                                      height: 95,
                                      width: 95,
                                      fit: BoxFit.cover,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Success message centered
                            const Text(
                              'Drawing successfully saved!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF4B3F3F),
                              ),
                            ),

                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Title cannot be empty.')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }


  /// 获取画板内容 Json `getJsonList()`
  Future<void> _getJson() async {
    showDialog<void>(
      context: context,
      builder: (BuildContext c) {
        return Center(
          child: Material(
            color: Colors.white,
            child: InkWell(
              onTap: () => Navigator.pop(c),
              child: Container(
                constraints:
                const BoxConstraints(maxWidth: 500, maxHeight: 800),
                padding: const EdgeInsets.all(20.0),
                child: SelectableText(
                  const JsonEncoder.withIndent('  ')
                      .convert(_drawingController.getJsonList()),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// 添加Json测试内容
  void _addTestLine() {
    _drawingController.addContent(StraightLine.fromJson(_testLine1));
    _drawingController
        .addContents(<PaintContent>[StraightLine.fromJson(_testLine2)]);
    _drawingController.addContent(SimpleLine.fromJson(tData[0]));
    _drawingController.addContent(Eraser.fromJson(tData[1]));
  }

  void _restBoard() {
    _transformationController.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: IconButton(
          icon: Image.asset('assets/backButton.png', width: 32),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('New Drawing'),
        actions: <Widget>[
          PopupMenuButton<Color>(
            icon: const Icon(Icons.color_lens),
            onSelected: (ui.Color value) {
              _drawingController.setStyle(
                color: value.withAlpha((_colorOpacity * 255).toInt()),
              );
            },
            itemBuilder: (_) {
              return <PopupMenuEntry<Color>>[
                PopupMenuItem<Color>(
                  enabled: false,
                  child: StatefulBuilder(
                    builder: (BuildContext context, setState) {
                      return Column(
                        children: [
                          const Text("Opacity"),
                          Slider(
                            min: 0,
                            max: 1,
                            divisions: 100,
                            value: _colorOpacity,
                            onChanged: (double v) {
                              setState(() => _colorOpacity = v);
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ),
                ...Colors.accents.map((Color color) {
                  return PopupMenuItem<Color>(
                    value: color.withAlpha((_colorOpacity * 255).toInt()),
                    child: Container(width: 100, height: 30, color: color),
                  );
                }).toList(),
              ];
            },
          ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _getImageData,
          ),
        ],
      ),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          systemNavigationBarColor: Colors.grey,
        ),
        child: SafeArea(
          child: Column(
            children: <Widget>[
              Expanded(
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    return DrawingBoard(
                      // boardPanEnabled: false,
                      // boardScaleEnabled: false,
                      transformationController: _transformationController,
                      controller: _drawingController,
                      background: Container(
                        width: constraints.maxWidth,
                        height: constraints.maxHeight,
                        color: Colors.white,
                      ),
                      showDefaultActions: true,
                      showDefaultTools: true,
                      defaultToolsBuilder: (Type t, _) {
                        return DrawingBoard.defaultTools(t, _drawingController)
                          ..insert(
                            1,
                            DefToolItem(
                              icon: Icons.change_history_rounded,
                              isActive: t == Triangle,
                              onTap: () => _drawingController
                                  .setPaintContent(Triangle()),
                            ),
                          );
                      },
                    );
                  },
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(4.0),

              ),
            ],
          ),
        ),
      ),
    );
  }
}
