// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import '../services/auth_service.dart';

class ApiService {
  // : Replace with your actual API base URL
  static const String baseUrl = 'https://your-api-url.com/api';

  // For Supabase-based API (example structure)
  // static const String supabaseUrl = 'https://your-project.supabase.co';
  // static const String supabaseAnonKey = 'your-anon-key';

  static Future<Map<String, dynamic>> login(
    String studentId,
    String password,
  ) async {
    try {
      // Example: Custom auth endpoint for Student ID login
      // final response = await http.post(
      //   Uri.parse('$baseUrl/auth/login'),
      //   headers: {
      //     'Content-Type': 'application/json',
      //   },
      //   body: jsonEncode({
      //     'studentId': studentId,
      //     'password': password,
      //   }),
      // );

      // For now, return a mock response structure
      // Replace this with actual API call
      await Future.delayed(
        const Duration(seconds: 1),
      ); // Simulate network delay

      // Mock response - replace with actual API call
      return {
        'session': {
          'access_token': 'mock_token_${DateTime.now().millisecondsSinceEpoch}',
          'user': {
            'id': 'user_${DateTime.now().millisecondsSinceEpoch}',
            'studentId': studentId,
            'name': 'User',
            'email':
                'student@university.edu', // Email can still be stored but not used for login
          },
        },
      };
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  static Future<Map<String, dynamic>> signup({
    required String email,
    required String password,
    required String name,
    required String studentId,
    required String university,
  }) async {
    try {
      // Example: Custom signup endpoint
      // final response = await http.post(
      //   Uri.parse('$baseUrl/signup'),
      //   headers: {
      //     'Content-Type': 'application/json',
      //   },
      //   body: jsonEncode({
      //     'email': email,
      //     'password': password,
      //     'name': name,
      //     'studentId': studentId,
      //     'university': university,
      //   }),
      // );

      // For now, return a mock response structure
      // Replace this with actual API call
      await Future.delayed(
        const Duration(seconds: 1),
      ); // Simulate network delay

      // Mock response - replace with actual API call
      return {
        'session': {
          'access_token': 'mock_token_${DateTime.now().millisecondsSinceEpoch}',
          'user': {
            'id': 'user_${DateTime.now().millisecondsSinceEpoch}',
            'email': email,
            'name': name,
            'studentId': studentId,
            'university': university,
          },
        },
      };
    } catch (e) {
      throw Exception('Signup failed: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getPosts() async {
    try {
      // final token = AuthService.getToken();

      // Example: Get posts endpoint
      // final response = await http.get(
      //   Uri.parse('$baseUrl/posts'),
      //   headers: {
      //     'Content-Type': 'application/json',
      //     if (token != null) 'Authorization': 'Bearer $token',
      //   },
      // );

      // For now, return mock data
      // Replace this with actual API call
      await Future.delayed(
        const Duration(milliseconds: 500),
      ); // Simulate network delay

      // Mock posts - replace with actual API call
      return [
        // Empty list for now - will be populated when API is connected
      ];
    } catch (e) {
      throw Exception('Failed to load posts: $e');
    }
  }
}
