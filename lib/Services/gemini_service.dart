import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {

  static const String apiKey =
      "AIzaSyAmlBCaSxp66WwEkRoxPFOCBrGfGzBZWDc";

  static const String url =
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-3-flash-preview:generateContent";

  static DateTime? lastRequestTime;

  Future<String> sendMessage(
      String message) async {

    try {

      /// Prevent rapid requests
      if (lastRequestTime != null) {

        final difference =
        DateTime.now()
            .difference(
            lastRequestTime!);

        if (difference.inSeconds < 3) {

          await Future.delayed(
              Duration(
                  seconds:
                  2 -
                      difference
                          .inSeconds));
        }
      }

      lastRequestTime =
          DateTime.now();

      final response =
      await http.post(

        Uri.parse(
            "$url?key=$apiKey"),

        headers: {
          "Content-Type":
          "application/json",
        },

        body: jsonEncode({

          "contents": [

            {
              "parts": [
                {"text": message}
              ]
            }

          ]

        }),
      );

      if (response.statusCode == 200) {

        final data =
        jsonDecode(
            response.body);

        return data["candidates"][0]
        ["content"]["parts"][0]
        ["text"];
      }

      /// Handle 429 properly
      if (response.statusCode == 429) {

        return "⚠️ Too many requests. Please wait 5 seconds and try again.";
      }

      return "Error: ${response.body}";

    } catch (e) {

      return " No Network Connection🛜 . Try again.";
    }
  }
}
