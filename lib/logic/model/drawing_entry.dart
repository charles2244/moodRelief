// lib/models/drawing_entry.dart
import 'content.dart'; // Import the Content interface

class DrawingEntry implements Content{
  @override
  final String id;
  @override
  final String title;
  final String imageData;
  final String canvasSize;
  @override
  final DateTime createdAt;

  DrawingEntry({
    required this.id,
    required this.title,
    required this.imageData,
    required this.canvasSize,
    required this.createdAt,
  });
}
