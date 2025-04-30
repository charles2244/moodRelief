import 'dart:typed_data';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/drawing_service.dart';
import '../logic/model/drawing_entry.dart';
import 'drawing_board.dart';
import 'Drawing_screen2.dart';
import 'fullScreenImage.dart';

// Change this to StatefulWidget
class DrawingScreen extends StatefulWidget {
  const DrawingScreen({super.key});

  @override
  State<DrawingScreen> createState() => _DrawingScreenState();
}

String _formatDate(DateTime dateTime) {
  return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
}

class _DrawingScreenState extends State<DrawingScreen> {
  List<DrawingEntry> recentDrawings = [];
  List<DrawingEntry> allDrawings = [];
  bool isLoading = true;
  bool isLoading1 = true;

  final _drawingService = DrawingService(); // Initialize service

  int? _userId;

  @override
  void initState() {
    super.initState();
    loadRecentDrawings();
    loadAllDrawings();
  }

  Future<void> loadRecentDrawings() async {
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
    try {
      final drawings = await _drawingService.fetchRecentDrawings(userId: _userId!);
      setState(() {
        recentDrawings = drawings;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading drawings: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> loadAllDrawings() async {
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
      final drawings = await _drawingService.fetchAllDrawings(userId: _userId!);
      setState(() {
        allDrawings = drawings;
        isLoading1 = false;
      });
    } catch (e) {
      print('Error loading drawings: $e');
      setState(() {
        isLoading1 = false;
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
              'Drawing',
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
      body: Padding(
        padding: const EdgeInsets.only(top: 16.0, left: 16, right: 16, bottom: 0),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView( // <-- Add SingleChildScrollView here
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const Text(
                'Start fresh',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () async { // <<== make it async
                  final result = await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const MyHomePage(),
                    ),
                  );
                  // After coming back, check if user saved a drawing
                  if (result == true) {
                    loadRecentDrawings();
                    loadAllDrawings();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC7B8F5),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'Blank Canvas',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Recent projects',
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: recentDrawings.length,
                  itemBuilder: (context, index) {
                    final drawing = recentDrawings[index];
                    return GestureDetector(
                        onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FullScreenImagePage(imageUrl: drawing.imageData),
                        ),
                      );
                    },
                    child: Container(
                      width: 150,
                      margin: const EdgeInsets.only(right: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: NetworkImage(drawing.imageData),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          color: Colors.black54,
                          padding: const EdgeInsets.all(4),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                drawing.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _formatDate(drawing.createdAt),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'All projects',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 8),
              // Grid of drawings
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 3 / 4,
                ),
                itemCount: allDrawings.length,
                itemBuilder: (context, index) {
                  final drawing = allDrawings[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FullScreenImagePage(imageUrl: drawing.imageData),
                        ),
                      );
                    },
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
                                                'assets/bunnyQuestionMark.gif', // Bunny
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

                        if (confirm == true) {
                          try {
                            // Call the drawing_service to delete
                            await _drawingService.deleteDrawing(drawing.imageData);
                            await _drawingService.deleteDrawingEntry(drawing.id);

                            setState(() {
                              allDrawings.removeWhere((d) => d.id == drawing.id);
                              recentDrawings.removeWhere((d) => d.id == drawing.id);
                            });

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
                                        'Drawing deleted',
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
                              SnackBar(content: Text('Error deleting drawing: $error')),
                            );
                          }
                        }
                      },
                      child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: NetworkImage(drawing.imageData),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          color: Colors.black54,
                          padding: const EdgeInsets.all(4),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                drawing.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _formatDate(drawing.createdAt),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              )

            ],
          ),
        ),
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
