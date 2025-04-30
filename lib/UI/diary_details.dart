import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import '../logic/model/diary_entry.dart'; // <-- Import your Diary model

class DiaryDetailPage extends StatelessWidget {
  final DiaryEntry diary; // <-- Corrected type here

  const DiaryDetailPage({Key? key, required this.diary}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Format the date and time
    String formattedDate = DateFormat('dd / MM / yyyy (EEE)').format(diary.createdAt);
    String formattedTime = DateFormat('h:mm a').format(diary.createdAt);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3EF), // Soft cream background
      appBar: AppBar(
        leading: IconButton(
          icon: Image.asset('assets/backButton.png', width: 32),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Diary Detail',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.purple, fontSize: 24),
        ),
        backgroundColor: const Color(0xFFEADFD8), // Purple shade
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, // Ensures space between the items
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    formattedDate,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.topLeft,
                  child: Text(
                    formattedTime.toLowerCase(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Title
            Text(
              diary.title ?? 'Untitled',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4B3F3F),
              ),
            ),
            const SizedBox(height: 16),

            // Diary content container
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade300,
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Text(
                    diary.content,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: Color(0xFF3C3C3C),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
