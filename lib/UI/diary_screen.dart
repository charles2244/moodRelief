import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/diary_service.dart';
import 'all_diary.dart';
import 'calendar_widget.dart';
import '../logic/controller/diary_controller.dart' hide DiaryEntry;
import 'diary_details.dart';
import 'write_diary_screen.dart';
import '../logic/model/diary_entry.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  final DiaryController controller = DiaryController();
  final DiaryService _diaryService = DiaryService();
  List<DiaryEntry> filteredEntries = [];
  bool isLoading = true;

  bool isSameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  int? _userId;

  @override
  void initState() {
    super.initState();
    loadFilteredDDiary();
  }

  Future<void> loadFilteredDDiary() async {
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
      final drawings = await _diaryService.fetchDiaryByDate(userId: userId, selectedDate: DateTime.now());
      setState(() {
        filteredEntries = drawings;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading drawings: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _fetchDiaries(DateTime selectedDate) async {
    final diaries = await _diaryService.fetchDiaryByDate(userId: _userId!, selectedDate: selectedDate);
    setState(() {
      filteredEntries = diaries;
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedMonth = controller.selectedDate != null
        ? DateFormat('dd MMMM yyyy').format(controller.selectedDate!).toUpperCase()
        : '';

    return Scaffold(
      backgroundColor: const Color(0xFFFBF7EF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBF7EF),
        elevation: 0,
        leading: IconButton(
          icon: Image.asset('assets/backButton.png', width: 32),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.black),
            onPressed: () async { // <<== make it async
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const WriteDiaryScreen(),
                ),
              );
              // After coming back, check if user saved a drawing
              if (result == true) {
                loadFilteredDDiary();
              }
            },
          )
        ],
        centerTitle: true,
        title: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Image.asset('assets/faceRightRabbit.png', width: 50),
                const Text(
                  'Diary',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.purple),
                ),
                Image.asset('assets/faceLeftRabbit.png', width: 50),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          CalendarWidget(
            selectedDate: controller.selectedDate ?? DateTime.now(),
            onDateSelected: (date) {
              setState(() {
                controller.selectDate(date); // Filter by day
              });
              // Fetch filtered diaries when a date is selected
              _fetchDiaries(date); // Pass userId and date to filter
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      controller.selectDate(DateTime.now()); // Filter by day
                    }); // (optional, depending on your state management)
                    _fetchDiaries(DateTime.now());
                  },
                  child: const Text('Today', style: TextStyle(color: Colors.purple)),
                ),
                Text(
                  selectedMonth,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16,),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AllDiary()),
                    );
                  },
                  child: const Text('View all', style: TextStyle(color: Colors.purple)),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: filteredEntries.length,
              itemBuilder: (context, index) {
                final entry = filteredEntries[index];
                return GestureDetector( // Wrap the Container with a GestureDetector
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
                                        'Are you sure to remove this diary?',
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
                          if (entry.id != null) {
                            await _diaryService.deleteDiaryEntry(entry.id!);
                          } else {
                            // Handle the case where diary.id is null
                            print('Diary ID is null');
                          }

                          // Remove the diary entry from the list
                          setState(() {
                            filteredEntries.removeWhere((d) => d.id == entry.id);
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DiaryDetailPage(diary: entry), // Navigate to detail page
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [ // <-- Add this
                      BoxShadow(
                        color: Colors.black12, // Shadow color
                        blurRadius: 8,          // How soft the shadow is
                        offset: Offset(0, 4),   // Position: x (right), y (down)
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              DateFormat('dd / MM / yyyy (EEE)').format(entry.createdAt), // Date format
                              style: const TextStyle(
                                fontWeight: FontWeight.normal,
                                fontSize: 12,
                                color: Colors.black,
                              ),
                            ),
                          ]
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (entry.title != null) ...[
                            Text(
                              entry.title!, // Display title
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(width: 8), // Add some space
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        entry.content,
                        style: const TextStyle(fontSize: 14, color: Colors.black),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              DateFormat('h:mm a').format(entry.createdAt), // Time
                              style: const TextStyle(
                                fontWeight: FontWeight.normal,
                                fontSize: 14,
                                color: Colors.black,
                              ),
                            ),
                          ]
                      )
                    ],
                  ),
                ));
              },
            ),
          ),
        ],
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
