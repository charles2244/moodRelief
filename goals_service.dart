import 'package:supabase_flutter/supabase_flutter.dart';
import '../controller/create_goal_strategy.dart';
import '../controller/goal_manager.dart';
import '../controller/goal_strategy.dart';
import '../controller/select_goals_strategy.dart';

class GoalsDatabase {
  final SelectGoalStrategy selectGoalStrategy;
  final CreateGoalStrategy createGoalStrategy;
  final GoalManager goalManager = GoalManager();
  final SupabaseClient _supabaseClient = Supabase.instance.client;
  String? _currentMood;
  final GoalStrategy goalStrategy;

  GoalsDatabase({required this.selectGoalStrategy, required this.createGoalStrategy, required this.goalStrategy});

  Future<String?> getCurrentMood(String userId) async {
    _currentMood = await goalManager.getCurrentMood(userId);
    return _currentMood;
  }

  Future<List<Map<String, dynamic>>> getGoalsForMood(String mood) async {
    final goals = await goalManager.getGoalsForMood(mood);

    // Remove duplicate goals based on 'goalid'
    final uniqueGoals = <int>{};
    final filteredGoals = goals.where((goal) => uniqueGoals.add(goal['goalid'])).toList();

    return filteredGoals;
  }

  Future<List<Map<String, dynamic>>> refreshGoals() async {
    if (_currentMood != null) {
      return goalManager.getGoalsForMood(_currentMood!);
    } else {
      throw Exception('Current mood is not available. Please fetch mood first.');
    }
  }

  Future<void> addSelectedGoal(String userId, String goalId) async {
    await selectGoalStrategy.selectGoal(userId, goalId);
  }

  Future<void> createUserGoal(int userId, String title, String description) async {
    await createGoalStrategy.createGoal(userId, title, description);
  }

  Future<List<Map<String, dynamic>>> getUserGoals(int userId) async {
    return goalManager.getUserGoals(userId);
  }

  Future<void> completeGoal(int goalId, String userId) async {
    await goalStrategy.completeGoal(goalId, userId);
  }

  Future<void> removeGoal(int goalId) async {
    await goalStrategy.removeGoal(goalId);
  }

  Future<void> removeUserCreatedGoal(int goalId) async {
    // Assuming you have a Supabase client instance
    final supabase = Supabase.instance.client;

    final response = await supabase
        .from('userCreateGoal')
        .delete()
        .eq('goalid', goalId);

    if (response.error != null) {
      throw Exception('Failed to remove user-created goal: ${response.error!.message}');
    }
  }

  Future<List<Map<String, dynamic>>> getCompletedGoals(int userId) async {
    return await goalManager.getCompletedGoalsWithDetails(userId); // Pass userId as int
  }

  Future<List<Map<String, dynamic>>> getUserSelectedGoals(int userId) async {
    final supabase = Supabase.instance.client;

    try {
      // Perform the select query
      final response = await supabase
          .from('userSelectedGoals')
          .select('goalid, goalStatus, goalType, goal (title, imageUrl)')
          .eq('userid', userId);

      // Check if the response is empty or null
      if (response == null || response.isEmpty) {
        throw Exception('No data found.');
      }

      // If response contains data, return it
      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      throw Exception('An error occurred: $error');
    }
  }

  Future<Map<String, dynamic>?> checkAchievement(int userId) async {
    final response = await Supabase.instance.client
        .from('UserSelectedGoals')
        .select('id')
        .eq('userid', userId)
        .eq('goalStatus', 'complete');

    final diaryCount = response.length;

    // Get diary-related achievements
    final achievementData = await _supabaseClient
        .from('achievement')
        .select('id, achievement_title')
        .like('achievement_title', '%Goal%')
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

        //return {'Achievement title': newAchievements};
      }
    }
    // After the loop, return the result if new ones were found
    if (newAchievements.isNotEmpty) {
      return {'Achievement title': newAchievements};
    }
    return null; // No new a`chievement
  }
}