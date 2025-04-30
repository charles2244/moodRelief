import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/diary_service.dart';
import '../logic/model/diary_entry.dart';
import 'diary_details.dart';

class AllDiary extends StatefulWidget {
  const AllDiary({super.key});

  @override
  State<AllDiary> createState() => _AllDiaryState();
}

class _AllDiaryState extends State<AllDiary> {
  List<DiaryEntry> allDiaries = [];
  bool isLoading = true;

  final DiaryService _diaryService = DiaryService();

  int? _userId;

  @override
  void initState() {
    super.initState();
    loadAllDiaries();
  }

  // Load diaries from the service
  Future<void> loadAllDiaries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final int? userId = prefs.getInt('user_id');

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
      _userId = userId;
      final diaries = await _diaryService.fetchAllDiary(userId: userId);
      setState(() {
        allDiaries = diaries;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading diaries: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF7EF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBF7EF),
        elevation: 0,
        leading: IconButton(
          icon: Image.asset('assets/backButton.png', width: 32),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.only(right: 30.0), // Add right padding to the left image
              child: Image.asset(
                'assets/faceRightRabbit.png',
                width: 50,
                height: 50,
              ),
            ),
            const Text(
              'All Diaries',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.purple),
            ),
            Padding(
              padding: EdgeInsets.only(left: 30.0), // Add left padding to the right image
              child: Image.asset(
                'assets/faceLeftRabbit.png',
                width: 50,
                height: 50,
              ),
            ),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : allDiaries.isEmpty
          ? const Center(child: Text('No diaries found.'))
          : ListView.builder(
        itemCount: allDiaries.length,
        itemBuilder: (context, index) {
          final diary = allDiaries[index];

          final dateFormatted = DateFormat('dd / MM / yyyy (EEE)').format(diary.createdAt);
          final timeFormatted = DateFormat('h:mm a').format(diary.createdAt);

          return GestureDetector(
            onLongPress: () async {
              final confirm = await showDialog<bool>(
                context: context,
                barrierDismissible: false, // Prevent closing by tapping outside
                builder: (context) => Dialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  backgroundColor: const Color(0xFFFBF7EF), // Light cream background
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Bunny and Message in Row
                        Row(
                          children: [
                            // Bunny image
                            ClipRRect(
                              borderRadius: BorderRadius.circular(50),
                              child: SizedBox(
                                height: 100,
                                width: 100,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Background image
                                    Image.asset(
                                      'assets/bunnyBackground.png', // Background
                                      height: 100,
                                      width: 100,
                                      fit: BoxFit.cover,
                                    ),
                                    // Bunny image
                                    Image.asset(
                                      'assets/bunny.png', // Bunny
                                      height: 75,
                                      width: 75,
                                      fit: BoxFit.cover,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),
                            // Message
                            Expanded(
                              child: Text(
                                'Are you sure to remove this drawing?',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF4B3F3F),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),

                        // Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF975EE0), // Purple color
                                  foregroundColor: Colors.white,      // Text color
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: const Text('No'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF975EE0), // Purple color
                                  foregroundColor: Colors.white,      // Text color
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: const Text('Yes'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
              // Inside your AllDiary widget
              if (confirm == true) {
                try {
                  // Call the diary_service to delete
                  if (diary.id != null) {
                    await _diaryService.deleteDiaryEntry(diary.id!);
                  } else {
                    // Handle the case where diary.id is null
                    print('Diary ID is null');
                  }

                  // Remove the diary entry from the list
                  setState(() {
                    allDiaries.removeWhere((d) => d.id == diary.id);
                  });

                  // Show a success message
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
                              'Diary deleted successfully!',
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting diary: $error')),
                  );
                }
              }
            },
            onTap: () {
              // Navigate to diary detail page
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DiaryDetailPage(diary: diary),
                ),
              );
            },
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          dateFormatted,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Title Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          diary.title ?? 'Untitled',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Content preview
                    Text(
                      diary.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 12),

                    // Time bottom right
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Text(
                        timeFormatted.toLowerCase(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 50),
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF975EE0), // Solid purple
          borderRadius: BorderRadius.circular(40), // Smooth rounded "pill" shape
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/home');
              },
              child: Image.asset(
                'assets/homeIcon.png',
                width: 30,
                height: 30,
                color: Colors.white,
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/gift');
              },
              child: Image.asset(
                'assets/RewardsIcon.png',
                width: 30,
                height: 30,
                color: Colors.white,
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/target');
              },
              child: Image.asset(
                'assets/GoalsIcon.png',
                width: 30,
                height: 30,
                color: Colors.white,
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/profile');
              },
              child: Image.asset(
                'assets/ProfileIcon.png',
                width: 30,
                height: 30,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
