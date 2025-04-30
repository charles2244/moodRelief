import 'package:flutter/material.dart';
import '../database/diary_service.dart';

class DiaryListPage extends StatefulWidget {
  const DiaryListPage({super.key});

  @override
  State<DiaryListPage> createState() => _DiaryListPageState();
}

class _DiaryListPageState extends State<DiaryListPage> {
  final DiaryService _diaryService = DiaryService();
  late Future<List<Map<String, dynamic>>> _diaryEntries;

  @override
  void initState() {
    super.initState();
    _diaryEntries = _diaryService.getDiaryEntries();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDE6FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEDE6FB),
        elevation: 0,
        title: const Text('Diary'),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _diaryEntries,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No diary entries found.'));
          }

          final entries = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  title: Text(entry['title'] ?? 'No Title'),
                  subtitle: Text(entry['content'] ?? 'No Content'),
                  trailing: Text(entry['created_at'] != null
                      ? DateTime.parse(entry['created_at']).toLocal().toString().substring(0, 16)
                      : ''),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
