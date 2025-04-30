import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../logic/model/drawing_entry.dart';
import 'factory/content_factory.dart';
import 'factory/drawing_factory.dart';

class DrawingService {
  final SupabaseClient _supabaseClient = Supabase.instance.client;
  final GoTrueClient _authClient = Supabase.instance.client.auth;
  final SupabaseStorageClient _storageClient = Supabase.instance.client.storage;
  final ContentFactory _drawingFactory = DrawingFactory();

  /// Uploads an image to Supabase Storage and returns the public URL.
  Future<String> _uploadImage(
      {required Uint8List imageData, required String filePath}) async {
    try {
      await _storageClient
          .from('image') //  <- Bucket name is "image"
          .uploadBinary(
        filePath,
        imageData,
      ); // Upload the binary image data

      final imageUrl = _storageClient.from('image').getPublicUrl(filePath);
      return imageUrl;
    } catch (e) {
      print('Error uploading image: $e');
      throw e;
    }
  }

  /// Saves a drawing to Supabase Storage and the database.
  Future<void> saveDrawing({
    required String title,
    required Uint8List imageData,
    required String canvasSize,
    required int userId,
  }) async {
    try {
      final dateNow = DateTime.now().toIso8601String();
      final filePath =
          'drawing/$title$dateNow.png'; // Path within the "image" bucket

      // 1. Upload the image and get the URL
      final imageUrl = await _uploadImage(
        imageData: imageData,
        filePath: filePath,
      );

      // 2. Insert into `content` and get the new ID
      final contentResponse = await _supabaseClient
          .from('content')
          .insert({
        'title': title,
        'user_id': userId,
      })
          .select('id, created_at') // Include created_at in the select
          .single();

      final contentId = contentResponse['id'];
      final createdAt = DateTime.parse(
          contentResponse['created_at']); // Parse created_at

      // 3. Create DrawingEntry object using the factory
      final drawingEntry = _drawingFactory.createContent({
        'id': contentId,
        'title': title,
        'image_data': imageUrl,
        'canvas_size': canvasSize,
        'created_at': createdAt.toIso8601String(), // Pass created_at as String
        'user_id': userId,
      }) as DrawingEntry; // Cast to DrawingEntry

      // 4. Insert into `drawing` using the DrawingEntry object
      await _supabaseClient.from('drawing').insert({
        'id': drawingEntry.id,
        'image_data': drawingEntry.imageData, // Use properties from the object
        'canvas_size': drawingEntry.canvasSize,
        'user_id':userId,
      });

      print(
          'Drawing saved successfully to Supabase Storage. URL: $imageUrl, DrawingEntry: ${drawingEntry.id}');
    } catch (error) {
      print('Error saving drawing: $error');
      throw error; // Re-throw to be caught in the UI
    }
  }

  Future<List<DrawingEntry>> fetchRecentDrawings({required int userId}) async {
    try {
      final response = await Supabase.instance.client
          .from('content')
          .select('id, title, created_at, drawing(image_data, canvas_size)')
          .eq('user_id', userId)
          .not('drawing', 'is', null)
          .order('created_at', ascending: false)
          .limit(5);

      if (response == null || response is! List) {
        throw Exception('Failed to fetch drawings');
      }

      return (response as List<dynamic>).where((data) {
        return data['drawing'] != null; // only take drawing type
      }).map((data) {
        final drawingData = data['drawing'];

        final imageUrl = drawingData?['image_data'] ?? ''; // Updated field name
        final canvasSize = drawingData?['canvas_size'] ?? '';

        return DrawingEntry(
          id: data['id'],
          title: data['title'] ?? 'Untitled',
          createdAt: DateTime.parse(data['created_at']),
          imageData: imageUrl, // This is now a URL string (not Uint8List)
          canvasSize: canvasSize,
          userId: userId,
        );
      }).toList();
    } catch (error, stackTrace) {
      print('Error fetching recent drawings: $error\n$stackTrace');
      return [];
    }
  }

  Future<List<DrawingEntry>> fetchAllDrawings({required int userId}) async {
    try {
      final response = await Supabase.instance.client
          .from('content')
          .select('id, title, created_at, drawing(image_data, canvas_size)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      if (response == null || response is! List) {
        throw Exception('Failed to fetch drawings');
      }

      return (response as List<dynamic>).where((data) {
        return data['drawing'] != null; // only take diary type
      }).map((data) {
        final drawingData = data['drawing'];

        final imageUrl = drawingData?['image_data'] ?? ''; // Updated field name
        final canvasSize = drawingData?['canvas_size'] ?? '';

        return DrawingEntry(
          id: data['id'],
          title: data['title'] ?? 'Untitled',
          createdAt: DateTime.parse(data['created_at']),
          imageData: imageUrl, // This is now a URL string (not Uint8List)
          canvasSize: canvasSize,
          userId: userId,
        );
      }).toList();
    } catch (error, stackTrace) {
      print('Error fetching recent drawings: $error\n$stackTrace');
      return [];
    }
  }

  // Delete a drawing from Supabase Storage and the database
  Future<void> deleteDrawing(String imageUrl) async {
    try {
      // Extract the file path from the URL
      final uri = Uri.parse(imageUrl);
      String filePath = uri.path;
      // Remove the leading '/storage/v1/object/public/'
      filePath = filePath.replaceFirst('/storage/v1/object/public/image/', '');

      await _storageClient.from('image').remove([filePath]);
      print('Image deleted from Supabase Storage: $filePath');
    } catch (error) {
      print('Error deleting image from Supabase Storage: $error');
      throw error; // Re-throw to be handled in the UI
    }
  }

  Future<void> deleteDrawingEntry(String id) async {
    try {
      await _supabaseClient.from('drawing').delete().eq('id', id);
      await _supabaseClient.from('content').delete().eq('id', id);
      print('Drawing entry deleted from database. ID: $id');
    } catch (error) {
      print('Error deleting drawing entry from database: $error');
      throw error; // Re-throw to be handled in the UI
    }
  }
}

