import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class FirstAidChatService {
  Future<String> sendMessage(String query) async {
    final uri = Uri.parse(ApiConfig.firstAidChat);
    final response = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'query': query}),
        )
        .timeout(ApiConfig.requestTimeout);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      final text = data['response']?.toString().trim();
      if (text == null || text.isEmpty) {
        throw Exception('Empty response from chatbot');
      }
      return text;
    }

    throw Exception('Chatbot request failed: ${response.statusCode}');
  }
}
