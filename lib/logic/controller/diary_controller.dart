import '../../database/diary_service.dart';

class DiaryController {
  DateTime? selectedDate = DateTime.now();

  final DiaryService _service = DiaryService();
  List<DiaryEntry> entries = [];

  // Future<void> loadEntries() async {
  //   entries = (await _service.fetchDiaryEntries()).cast<DiaryEntry>();
  // }

  void selectDate(DateTime date) {
    selectedDate = date;
  }

  List<DiaryEntry> get filteredEntries {
    if (selectedDate == null) return entries;
    return entries.where((entry) =>
    entry.date.year == selectedDate!.year &&
        entry.date.month == selectedDate!.month &&
        entry.date.day == selectedDate!.day
    ).toList();
  }
}



// lib/data/diary_repository.dart
class DiaryEntry {
  final DateTime date;
  final String content;

  DiaryEntry({required this.date, required this.content});
}

class DiaryRepository {
  static final List<DiaryEntry> _entries = [
    DiaryEntry(
      date: DateTime(2025, 2, 13, 15, 0),
      content: "We’ve finally got one! My mum has been trying to persuade my dad ...",
    ),
    DiaryEntry(
      date: DateTime(2025, 1, 23, 16, 0),
      content: "I picked her up and brought her into the house. Our house is quite small...",
    ),
    DiaryEntry(
      date: DateTime(2025, 1, 10, 17, 0),
      content: "I was a bit worried at first because there was no one there but...",
    ),
  ];

  static List<DiaryEntry> getEntriesForDate(DateTime date) {
    return _entries.where((entry) =>
    entry.date.year == date.year &&
        entry.date.month == date.month).toList();
  }
}

