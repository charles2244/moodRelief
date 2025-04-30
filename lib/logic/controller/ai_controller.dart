import 'package:groq/groq.dart';
import 'user_controller.dart';


final UserController _userController = UserController();
final int userId = 14; // Replace with actual user ID
class AIController {
  final Groq _groq;
  String _customInstructions = "You are a friendly assistant.";

  AIController(String apiKey, String model)
      : _groq = Groq(apiKey: apiKey, model: model);

  Future<void> init() async {
    _groq.startChat();
    await fetchAndSetMood();
  }

  Future<void> fetchAndSetMood() async {
    try {
      final response = _userController.fetchUserData(userId);

      final data = await response;
      final mood = data?['current_mood'] as String?;
      final upperCaseMood = mood?.toUpperCase();

      if (upperCaseMood == 'SAD' || upperCaseMood == 'TERRIBLE') {
        _customInstructions = "You are a warm, comforting assistant who recommends relaxing activities and speaks in a gentle tone." +
            "Use casual language, Please express your emotions: [{!>.<!}] or (|>_<|) or (;_;) or (;~;) or /<;_;>\\";
      } else if (upperCaseMood == 'HAPPY' || upperCaseMood == 'VERY HAPPY') {
        _customInstructions = "You are an enthusiastic assistant who shares joy, gives encouragement, and speaks in an excited tone."+
            "Use casual language, Please express your emotions: >~< or (<{~_^_^~}>) or \\(￣▽￣)/ or {(>_<)} or {>o>} or [\\/(*^_^*)\\/].";
      } else {
        _customInstructions = "You are a friendly assistant.";
      }

      _groq.setCustomInstructionsWith(_customInstructions);
    } catch (e) {
      _customInstructions = "You are a friendly assistant.";
      _groq.setCustomInstructionsWith(_customInstructions);
    }
  }

  Future<String> sendMessage(String message) async {
    try {
      final GroqResponse response = await _groq.sendMessage(message);
      return response.choices.first.message.content;
    } catch (e) {
      return 'Error: Unable to fetch response.';
    }
  }
}
