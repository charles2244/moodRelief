import 'content_factory.dart'; // Import the ContentFactory interface
import '../../logic/model/diary_entry.dart'; // Import the DiaryEntry class
import '../../logic/model/content.dart';

class DiaryFactory implements ContentFactory {
  @override
  Content createContent(Map<String, dynamic> data) {
    return DiaryEntry.fromJson(data);
  }
}