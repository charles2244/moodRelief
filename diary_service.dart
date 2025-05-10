import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../controller/diary_controller.dart';
import '../../UI/Drawing_screen2.dart';
import 'content_factory.dart';
import 'diary_factory.dart';

class DiaryService {
  final SupabaseClient _supabaseClient = Supabase.instance.client;
  final GoTrueClient _authClient = Supabase.instance.client.auth;
  final SupabaseStorageClient _storageClient = Supabase.instance.client.storage;
  final ContentFactory _diaryFactory = DiaryFactory();

  Future<List<Map<String, dynamic>>> getDiaryEntries() async {
    final List<dynamic> data = await _supabaseClient
        .from('diary') // Replace with your actual table name
        .select()
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  Future<Map<String, dynamic>?> checkAchievement(int userId) async {
    final response = await Supabase.instance.client
        .from('diary')
        .select('id')
        .eq('user_id', userId);

    final diaryCount = response.length;

    // Get diary-related achievements
    final achievementData = await _supabaseClient
        .from('achievement')
        .select('id, achievement_title')
        .like('achievement_title', '%Diary%')
        .lte('criteria_count', diaryCount); // Use lte = "less than or equal"

    // Fetch user's existing achievements
    final achievedList = await _supabaseClient
        .from('achieve_achievement')
        .select('achievement_id')
        .eq('user_id', userId);

    List<int> achievedIds = achievedList.map((a) => a['achievement_id'] as int).toList();

    // List to store new achievement titles
    List<String> newAchievements = [];

    // Insert new achievements
    for (final achievement in achievementData) {
      final achievementId = achievement['id'];

      if (!achievedIds.contains(achievementId)) {
        await _supabaseClient.from('achieve_achievement').insert({
          'user_id': userId,
          'achievement_id': achievementId,
          'isUnlocked': true,
          'is_claimed': false
        });

        print('Diary Count: $diaryCount');
        print('Achieved IDs: $achievedIds');
        print('Achievement Data: $achievementData');
        print('Achievement ID: ${achievement['id']}');

        newAchievements.add(achievement['achievement_title']);

        return {'Achievement title': newAchievements};
      }
    }

    return null; // No new a`chievement
  }

  Future<void> saveDiaryEntry({String? title, required String content, required int userId,}) async {
    try {
      if (userId == null) {
        throw Exception("User not authenticated");
      }

      // STEP 1: Create DiaryEntry using the DiaryFactory
      final factory = DiaryFactory();
      final diaryEntry = factory.createContent({
        'id': '', // Empty, Supabase will generate it (or you can handle it later)
        'title': title ?? '',
        'content': content,
        'mood_tag': null,
        'created_at': DateTime.now().toIso8601String(),
        'user_id': userId,
      }) as DiaryEntry;

      // STEP 2: Insert into `content` table first
      final response = await _supabaseClient
          .from('content')
          .insert({
        'title': diaryEntry.title,
        'user_id': diaryEntry.userId,
      })
          .select('id')
          .single();

      final contentId = response['id'];

      // STEP 3: Now insert into `diary` table
      await _supabaseClient
          .from('diary')
          .insert({
        'id': contentId,
        'content': diaryEntry.content,
        'user_id':userId,
      });
    } catch (error) {
      print('Error saving diary entry to Supabase: $error');
      throw error;
    }
  }

  Future<List<DiaryEntry>> fetchAllDiary({required int userId}) async {
    try {
      final response = await _supabaseClient
          .from('content')
          .select('id, title, created_at, diary(content, mood_tag)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      if (response == null || response is! List) {
        throw Exception('Failed to fetch diaries');
      }

      return (response as List<dynamic>).where((data) {
        return data['diary'] != null; // only take diary type
      }).map((data) {
        final diaryData = data['diary'];

        final content = diaryData?['content'] ?? '';
        final mood = diaryData?['mood_tag'] ?? '';

        return DiaryEntry(
          id: data['id'].toString(),
          title: data['title'] ?? 'Untitled',
          createdAt: DateTime.parse(data['created_at']),
          content: content,
          moodTag: mood,
          userId: userId,
        );
      }).toList();
    } catch (error, stackTrace) {
      print('Error fetching diaries: $error\n$stackTrace');
      return [];
    }
  }

  // final Map<String, dynamic> diaryMap = {
  //   'id': data['id'].toString(),
  //   'title': data['title'] ?? 'Untitled',
  //   'created_at': DateTime.parse(data['created_at']),
  //   'content': content,
  //   'mood_tag': mood,
  // };
  // return _diaryFactory.createContent(diaryMap) as DiaryEntry; // Use factory

  Future<List<DiaryEntry>> fetchDiaryByDate({
    required int userId,
    required DateTime selectedDate,
  }) async {
    try {
      // Format the selectedDate to get the start of the day and end of the day
      final startOfDay = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final response = await _supabaseClient
          .from('content')
          .select('id, title, created_at, diary(content, mood_tag)')
          .eq('user_id', userId)
          .gte('created_at', startOfDay.toIso8601String()) // Greater than or equal to start of the day
          .lt('created_at', endOfDay.toIso8601String())  // Less than the end of the day
          .order('created_at', ascending: false);

      if (response == null || response is! List) {
        throw Exception('Failed to fetch diaries');
      }

      return (response as List<dynamic>).where((data) {
        return data['diary'] != null; // only take diary type
      }).map((data) {
        final diaryData = data['diary'];
        final content = diaryData?['content'] ?? '';
        final mood = diaryData?['mood_tag'] ?? '';

        return DiaryEntry(
          id: data['id'].toString(),
          title: data['title'] ?? 'Untitled',
          createdAt: DateTime.parse(data['created_at']),
          content: content,
          moodTag: mood,
          userId: userId,
        );
      }).toList();
    } catch (error, stackTrace) {
      print('Error fetching diaries: $error\n$stackTrace');
      return [];
    }
  }

  Future<void> deleteDiaryEntry(String diaryId) async {
    try {
      await _supabaseClient.from('diary').delete().eq('id', diaryId);
      await _supabaseClient.from('content').delete().eq('id', diaryId);
      print('Driary entry deleted from database. ID: $diaryId');
    } catch (error) {
      print('Error deleting diary entry from database: $error');
      throw error; // Re-throw to be handled in the UI
    }
  }


  // Future<Map<String, dynamic>?> checkAchievement(int userId) async {
  //   final diaryEntries = await _supabaseClient
  //       .from('diary')
  //       .select('id')
  //       .eq('user_id', userId);
  //
  //   int diaryCount = diaryEntries.length;
  //
  //   final achievementData = await _supabaseClient
  //       .from('achievement')
  //       .select('criteria_count, achievement_title')
  //       .like('achievement_title', '%diary%')
  //       .order('criteria_count', ascending: false)
  //       .limit(1);
  //
  //   if (achievementData.isNotEmpty) {
  //     int criteriaCount = achievementData[0]['criteria_count'] as int;
  //     String title = achievementData[0]['achievement_title'] as String;
  //
  //     if (diaryCount >= criteriaCount) {
  //       // final inserted = await _supabaseClient
  //       //     .from('achieve_achievement')
  //       //     .insert({
  //       //     'user_id': userId,
  //       //     'achievement_id': achievementId,
  //       //     'isUnlocked': true,
  //       //     'is_claimed': false,
  //       //     'claimed_at': DateTime.now().toIso8601String();
  //       return {'title': title};  // ✅ Returns achievement data instead of `void`
  //     }
  //   }
  //   return null; // No achievement unlocked
  // }


}