// import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';
// import 'dart:io';

class UserService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<void> insertUserData(
    String name,
    int? age,
    int? emergencyContact,
    String safetyTime,
    String followUpTime,
  ) async {
    try {
      await _client.from('users').insert({
        'name': name,
        'age': age,
        'emergency_contact': emergencyContact,
        'points': 0,
        'follow_time': followUpTime,
        'safe_time': safetyTime,
      });
    } catch (e) {
      throw Exception('Failed to insert user data: $e');
    }
  }

  Future<void> insertAUserData(
      int? id,
      ) async {
    try {
      await _client.from('users').insert({
        'id': id,
      });
    } catch (e) {
      throw Exception('Failed to insert user data: $e');
    }
  }

  Future<Map<String, dynamic>?> getUserData(int userId) async {
    try {
      final response =
          await _client
              .from('users')
              .select()
              .match({'id': userId})
              .limit(1)
              .single();
      return response;
    } catch (e) {
      throw Exception('Failed to fetch user data: $e');
    }
  }

  Future<void> updateUserImage(int userId, String imageUrl) async {
    try {
      await _client.from('users').update({'user_image': imageUrl}).match({'id': userId});
    } catch (e) {
      throw Exception('Failed to update user image: $e');
    }
  }

  Future<void> updateUserField(int userId, String field, String newValue) async {
      await Supabase.instance.client
          .from('users')
          .update({field: newValue})
          .eq('id', userId);
  }
}
