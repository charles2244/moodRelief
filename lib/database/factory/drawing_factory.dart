import 'content_factory.dart'; // Import the ContentFactory interface
import '../../logic/model/drawing_entry.dart';
import '../../logic/model/content.dart';

class DrawingFactory implements ContentFactory {
  @override
  Content createContent(Map<String, dynamic> data) {
    // You might need to adjust this based on how drawing data is structured
    return DrawingEntry(
      id: data['id'],
      title: data['title'],
      imageData: data['image_data'],
      canvasSize: data['canvas_size'],
      createdAt: DateTime.parse(data['created_at']),
    );
  }
}