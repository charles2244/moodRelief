import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/diary_service.dart';
import '../../logic/model/diary_entry.dart';

class AddDiaryScreen extends StatefulWidget {
  const AddDiaryScreen({super.key});

  @override
  State<AddDiaryScreen> createState() => _AddDiaryScreenState();
}

class _AddDiaryScreenState extends State<AddDiaryScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  String _selectedMood = 'Neutral';

  final List<String> _moods = ['Happy', 'Sad', 'Neutral', 'Excited', 'Reflective', 'Curious'];

  Future<void> _saveDiary() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in both title and content')),
      );
      return;
    }

  //   final entry = DiaryEntry(
  //     title: title,
  //     content: content,
  //     mood: _selectedMood,
  //     date: DateTime.now(),
  //   );
  //
  //   await DiaryService.saveDiaryEntry();
  //   Navigator.pop(context); // Go back to diary list
   }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3E8FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3E8FF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: const Text(
          'New Diary Entry',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Date: ${DateFormat('dd MMM yyyy – hh:mm a').format(DateTime.now())}',
                style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 16),

            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _contentController,
              maxLines: 10,
              decoration: const InputDecoration(
                labelText: 'What\'s on your mind?',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: _selectedMood,
              items: _moods
                  .map((mood) => DropdownMenuItem(value: mood, child: Text(mood)))
                  .toList(),
              onChanged: (value) => setState(() => _selectedMood = value!),
              decoration: const InputDecoration(
                labelText: 'Mood',
                border: OutlineInputBorder(),
              ),
            ),
            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveDiary,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'Save Entry',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
