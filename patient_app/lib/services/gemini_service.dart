import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class GeminiService {
  final List<Map<String, dynamic>> _history = [];

  Future<Map<String, dynamic>> sendMessage(String userMessage) async {
    try {
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/'
        '${AppConstants.geminiModel}:generateContent'
        '?key=${AppConstants.geminiApiKey}',
      );

      List<Map<String, dynamic>> contents = [];

      if (_history.isEmpty) {
        contents.add({
          'role': 'user',
          'parts': [{'text': AppConstants.systemPrompt}]
        });
        contents.add({
          'role': 'model',
          'parts': [
            {
              'text':
                  '{"message": "Hello! I am MediBot. Please describe your symptoms and I will guide you to the right medical care.", "urgency": "none", "specialist": "", "is_final": false, "followup_question": "", "quick_replies": [], "show_appointment": false, "show_medicine": false, "show_lab_test": false, "checklist": [], "precautions": []}'
            }
          ]
        });
      }

      contents.addAll(_history);
      contents.add({
        'role': 'user',
        'parts': [{'text': userMessage}]
      });

      final body = json.encode({
        'contents': contents,
        'generationConfig': {
          'temperature': 0.7,
          'maxOutputTokens': 1000,
        }
      });

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final text = data['candidates'][0]['content']['parts'][0]['text'] as String;

        _history.add({
          'role': 'user',
          'parts': [{'text': userMessage}]
        });
        _history.add({
          'role': 'model',
          'parts': [{'text': text}]
        });

        return _parseResponse(text);
      } else {
        print('Gemini API Error: ${response.statusCode}');
        print('Body: ${response.body}');
        return _errorResponse();
      }
    } catch (e) {
      print('Gemini Error: $e');
      return _errorResponse();
    }
  }

  Map<String, dynamic> _parseResponse(String responseText) {
    try {
      String cleaned = responseText
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      int start = cleaned.indexOf('{');
      int end = cleaned.lastIndexOf('}');
      if (start != -1 && end != -1) {
        cleaned = cleaned.substring(start, end + 1);
      }

      Map<String, dynamic> result = json.decode(cleaned);

      if (result['specialist'] == null ||
          result['specialist'].toString().isEmpty) {
        result['specialist'] = 'general-physician';
      }

      return result;
    } catch (e) {
      print('Parse Error: $e');
      return {
        'message': responseText,
        'urgency': 'none',
        'specialist': 'general-physician',
        'is_final': false,
        'followup_question': '',
        'quick_replies': [],
        'show_appointment': false,
        'show_medicine': false,
        'show_lab_test': false,
        'checklist': [],
        'precautions': [],
      };
    }
  }

  Map<String, dynamic> _errorResponse() {
    return {
      'message': 'Sorry, I am having trouble. Please try again.',
      'urgency': 'none',
      'specialist': '',
      'is_final': false,
      'followup_question': '',
      'quick_replies': [],
      'show_appointment': false,
      'show_medicine': false,
      'show_lab_test': false,
      'checklist': [],
      'precautions': [],
    };
  }

  void resetChat() => _history.clear();
}
