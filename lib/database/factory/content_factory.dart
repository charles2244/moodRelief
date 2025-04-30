// lib/factories/content_factory.dart
import '../../../logic/model/content.dart'; // Import the Content interface

abstract class ContentFactory {
  Content createContent(Map<String, dynamic> data);
}