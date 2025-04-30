// lib/UI/write_diary_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../logic/model/diary_entry.dart'; // Import your DiaryEntry model
import '../database/diary_service.dart'; // Import your DiaryService
import '../logic/controller/ai_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WriteDiaryScreen extends StatefulWidget {
  const WriteDiaryScreen({super.key});

  @override
  State<WriteDiaryScreen> createState() => _WriteDiaryScreenState();
}

class _WriteDiaryScreenState extends State<WriteDiaryScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final DiaryService _diaryService = DiaryService();

  Future<void> _saveDiaryEntry(BuildContext context) async {
    final String title = _titleController.text.trim();
    final String content = _contentController.text.trim();
    const int maxTitleLength = 35;

    if (title.length > maxTitleLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Title cannot exceed 35 characters.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (content.isNotEmpty) {
      // Call your DiaryService to save the data
      try {
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

        await _diaryService.saveDiaryEntry(title: title, content: content, userId: userId,);

        // Send content to GROQ API for emotional analysis
        final AIController aiController = AIController(
          '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',
          "meta-llama/llama-4-scout-17b-16e-instruct",
        );
        await aiController.init();
        final analysisResult = await aiController.sendMessage(
          "Analyze the emotion of this text: $content" + "then give me only negative or positive word to represent overall analysis",
        );

        print('GROQ analysis raw result: $analysisResult');

        String message;
        if (analysisResult.contains('negative')) {
          message = await aiController.sendMessage(
              "Suggest relaxing activities for someone feeling negative emotions."
          );
        } else {
          message = await aiController.sendMessage(
              "Give a compliment or uplifting message for someone feeling positive emotions."
          );
        }

        // Show the message in a dialog
        await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Emotion Analysis Result'),
              content: Text(message),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );

        Navigator.of(context).pop(true); // Go back to the diary screen

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
                    'Diary successfully saved!',
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

      } catch (error) {
        // Handle any errors during saving
        print('Error saving diary entry: $error');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save diary entry.')),
        );
      }
    } else {
      // Show an error if the content is empty
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
                  'Diary content cannot be empty.',
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF7EF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Image.asset('assets/backButton.png', width: 32),
          onPressed: () => _handleBackPressed(context),
        ),
        title: const Text('New Diary', style: TextStyle(color: Colors.black)),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.black),
            onPressed: () => _saveDiaryEntry(context), // Call the save function
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Date: ${DateFormat('dd MMM yyyy – hh:mm a').format(DateTime.now())}',
                style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 16),

            TextField(
              controller: _titleController, // Attach the title controller
              decoration: const InputDecoration(
                hintText: 'Title (Optional)',
                border: InputBorder.none,
              ),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TextField(
                controller: _contentController, // Attach the content controller
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(
                  hintText: 'Write your thoughts here...',
                  border: InputBorder.none,
                ),
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleBackPressed(BuildContext context) {
    if (_titleController.text.trim().isNotEmpty || _contentController.text.trim().isNotEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Discard changes?'),
            content: const Text('You have unsaved changes. Are you sure you want to discard them?'),
            actions: [
              TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.of(context).pop(), // Close dialog
              ),
              TextButton(
                child: const Text('Discard'),
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(); // Go back
                },
              ),
            ],
          );
        },
      );
    } else {
      Navigator.of(context).pop(); // Go back normally
    }
  }

}