import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import '../../database/user_service.dart';

class UserController {
  final UserService _userService = UserService();

  Future<Map<String, dynamic>?> fetchUserData(int userid) async {
    return await _userService.getUserData(userid);
  }

  Future<void> saveUserData(
    String name,
    int? age,
    int? emergencyContact,
    String safetyTime,
    String followUpTime,
  ) async {
    await _userService.insertUserData(
      name,
      age,
      emergencyContact,
      safetyTime,
      followUpTime,
    );
  }

  Future<void> saveAUserData(
      int? id,
      ) async {
    await _userService.insertAUserData(
      id,
    );
  }

  Future<void> updateUserData(int userId, String field, String newValue) async {
    try {
      await _userService.updateUserField(userId, field, newValue);
    } catch (e) {
      throw Exception('Failed to update user data: $e');
    }
  }

  Future<void> uploadUserImage(int userId, File imageFile) async {
    try {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final path = 'user_images/$fileName';

      // Upload the image to Supabase storage
      await Supabase.instance.client.storage
          .from('image')
          .upload(path, imageFile);

      // Get the public URL of the uploaded image
      final publicUrl = Supabase.instance.client.storage
          .from('image')
          .getPublicUrl(path);

      // Update the user_image field in the users table
      await _userService.updateUserImage(userId, publicUrl);
    } catch (e) {
      throw Exception('Error uploading user image: $e');
    }
  }

  // bool isLoggedIn() {
  //   final userData = _sessionManager.getUserData();
  //   return userData != null;
  // }
}
