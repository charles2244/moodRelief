import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zenzone2/UI/diary_screen.dart';
import 'package:zenzone2/UI/drawing_screen.dart';
import 'login.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://qnvoajikwadxpgertimm.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFudm9hamlrd2FkeHBnZXJ0aW1tIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDUzNzQ3NDAsImV4cCI6MjA2MDk1MDc0MH0.l_20rtGh4ZOLXNkVBLhhdKy3TSQBTt3ugosmi8XFigI',
  );
  runApp(ReliefMoodApp());
}

class ReliefMoodApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: {
        '/home': (context) => ReliefMoodHome(),
        //'/gift': (context) => GiftScreen(),
        //'/target': (context) => TargetScreen(),
        //'/profile': (context) => ProfileScreen(),
      },

      debugShowCheckedModeBanner: false,
      title: 'Relief ',
      theme: ThemeData(fontFamily: 'Arial'),
      home: FingerprintLoginScreen(),
    );
  }
}

class ReliefMoodHome extends StatelessWidget {
  final Color softPurple = Color(0xFFCAD6FF);
  final Color lightPurple = Color(0xFFFBF7EF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightPurple,
      appBar: AppBar(
        backgroundColor: lightPurple,
        elevation: 0,
        leading: IconButton(
          icon: Image.asset(
            'assets/backButton.png', // 👈 Your custom image
            width: 32,
            height: 32,
          ),
          onPressed: () {
            // Navigator.of(context).pop(); // 👈 Navigate back
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Image.asset("assets/faceRightRabbit.png", width: 80),
                Text(
                  "Relief\nMood",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
                Image.asset("assets/faceLeftRabbit.png", width: 80),
              ],
            ),
            SizedBox(height: 30),
            OptionTile(
              leading: Image.asset("assets/writeDiary.png", width: 52, height: 52),
              text: "Diary",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DiaryScreen(), // Replace with your class name
                  ),
                );
              },
            ),
            SizedBox(height: 30),
            OptionTile(
              leading: Image.asset("assets/drawing.png", width: 45, height: 45),
              text: "Drawing",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DrawingScreen(), // Replace with your class name
                  ),
                );
              },
            ),
            SizedBox(height: 30),
            OptionTile(
              leading: Image.asset("assets/AIbot.png", width: 48, height: 48),
              text: "Chat with AI",
              onTap: () {},
            ),
          ],
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
                // Navigate to Home Screen
                Navigator.pushNamed(context, '/home');
              },
              child: Image.asset(
                'assets/homeIcon.png', // Replace with your actual asset path
                width: 30,
                height: 30,
                color: Colors.white,
              ),
            ),
            GestureDetector(
              onTap: () {
                // Navigate to Gift Screen
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
                // Navigate to Target Screen
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
                // Navigate to Profile Screen
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

class OptionTile extends StatelessWidget {
  final Widget leading; // Now accepts either Icon or Image
  final String text;
  final VoidCallback onTap;

  const OptionTile({
    required this.leading,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        decoration: BoxDecoration(
          color: Color(0xFFCAD6FF),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            leading,
            SizedBox(width: 16),
            Text(
              text,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}