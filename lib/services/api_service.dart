import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/attendance.dart';
import '../models/user.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

// Platform-specific imports
// For mobile platforms
import 'dart:io' as io;
// For web platform - using universal_html for better compatibility
import 'package:universal_html/html.dart' as html;
// For file handling on mobile
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:permission_handler/permission_handler.dart';
// For Android DownloadManager
import 'package:flutter/services.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as path_lib;

class ApiService {
  // Admin: Reset any user's password to 'password123'
  Future<void> adminResetUserPassword(String userId, String userType) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final url = await baseUrl;
    final response = await http.post(
      Uri.parse('$url/auth/admin-reset-password'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'userId': userId, 'userType': userType}),
    );
    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Failed to reset password');
    }
  }

  // Default server URLs
  final String _defaultWebUrl = 'http://localhost:3000/api';
  final String _defaultAndroidEmulatorUrl = 'http://192.168.156.241:3000/api'; // Android emulator URL
  final String _defaultPhysicalDeviceUrl = 'http://192.168.156.241:3000/api'; // Change this to your computer's IP address

  // Get the base URL based on platform
  Future<String> get baseUrl async {
    final prefs = await SharedPreferences.getInstance();
    // Check if a custom URL is saved in preferences
    final savedUrl = prefs.getString('api_base_url');
    if (savedUrl != null && savedUrl.isNotEmpty) {
      return savedUrl;
    }
    
    // Return default URL based on platform
    if (kIsWeb) {
      return _defaultWebUrl;
    } else {
      try {
        // For Android and iOS devices, use the physical device URL
        // This allows connecting to your computer's IP address
        return _defaultPhysicalDeviceUrl;
      } catch (e) {
        // If we can't determine the platform, default to web URL
        print('Error determining platform: $e');
        return _defaultWebUrl;
      }
    }
  }
  
  // Method to set a custom base URL
  Future<void> setBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_base_url', url);
  }

  Future<Map<String, dynamic>> login(String id, String password, String role) async {
    final url = await baseUrl;
    final response = await http.post(
      Uri.parse('$url/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'id': id, 'password': password, 'role': role}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', data['token']);
      return data;
    }
    throw Exception('Login failed');
  }

  

  Future<void> markAttendance(String projectId, String date, List<String> absentStudents, List<int> periods, {bool isEdit = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token == null) {
        throw Exception('Authentication token not found. Please login again.');
      }

      final url = await baseUrl;
      final response = await http.post(
        Uri.parse('$url/attendance/mark'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: jsonEncode({
          'projectId': projectId,
          'date': date,
          'absentStudents': absentStudents,
          'periods': periods,
          'isEdit': isEdit,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['message'] == 'Attendance marked successfully') {
          return;
        }
        throw Exception(responseData['message'] ?? 'Failed to mark attendance');
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Invalid request');
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else if (response.statusCode == 404) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Resource not found');
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to mark attendance');
      }
    } catch (e) {
      print('Error in markAttendance: $e');
      if (e is Exception) {
        throw e;
      }
      throw Exception('Failed to mark attendance. Please try again.');
    }
  }

  Future<Attendance> getStudentAttendance(String studentId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final url = await baseUrl;
    final response = await http.get(
      Uri.parse('$url/attendance/student/$studentId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return Attendance.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to fetch attendance');
  }

  Future<List<Map<String, String>>> getStudentsByProjectId(String projectId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final url = await baseUrl;
      final response = await http.get(
        Uri.parse('$url/attendance/students/$projectId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((student) => {
          'studentId': student['studentId'] as String,
          'name': student['name'] as String,
        }).toList();
      } else if (response.statusCode == 404) {
        return [];
      } else {
        throw Exception('Failed to fetch students: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getStudentsByProjectId: $e');
      throw Exception('Failed to fetch students. Please try again.');
    }
  }

  Future<Map<String, dynamic>?> getAttendanceForDate(String projectId, String date) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final url = await baseUrl;
    final response = await http.get(
      Uri.parse('$url/attendance/check?projectId=$projectId&date=$date'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }

  Future<Map<String, dynamic>?> getAttendanceDetails(String projectId, String date) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final url = await baseUrl;
      final response = await http.get(
        Uri.parse('$url/attendance/details?projectId=$projectId&date=$date'),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Failed to fetch attendance details: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getAttendanceDetails: $e');
      throw Exception('Failed to fetch attendance details. Please try again.');
    }
  }

  Future<void> resetPassword(String currentPassword, String newPassword) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token == null) {
        throw Exception('Authentication token not found. Please login again.');
      }

      final url = await baseUrl;
      // Log the request details
      print('Sending reset password request to: $url/auth/reset-password');
      print('Headers: ${{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      }}');

      final response = await http.post(
        Uri.parse('$url/auth/reset-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: jsonEncode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );

      // Log the response details
      print('Response status code: ${response.statusCode}');
      print('Response headers: ${response.headers}');
      print('Response body: ${response.body}');

      // Check if response is HTML
      if (response.headers['content-type']?.contains('text/html') ?? false) {
        print('Received HTML response instead of JSON');
        throw Exception('Server error: Please try again later');
      }

      // Try to parse JSON response
      Map<String, dynamic>? responseData;
      try {
        responseData = jsonDecode(response.body);
        print('Parsed response data: $responseData');
      } catch (e) {
        print('Error parsing JSON response: $e');
        throw Exception('Invalid server response. Please try again.');
      }

      if (response.statusCode == 200) {
        return;
      } else if (response.statusCode == 400) {
        throw Exception(responseData?['message'] ?? 'Invalid request');
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else if (response.statusCode == 404) {
        throw Exception('Reset password endpoint not found. Please contact support.');
      } else if (response.statusCode == 500) {
        print('Server error details: ${responseData?['error']}');
        throw Exception('Server error. Please try again later or contact support.');
      } else {
        throw Exception(responseData?['message'] ?? 'Failed to reset password');
      }
    } catch (e) {
      print('Error in resetPassword: $e');
      print('Stack trace: ${StackTrace.current}');
      if (e is Exception) {
        throw e;
      }
      throw Exception('Failed to reset password. Please try again or contact support.');
    }
  }

  Future<void> createProject(Map<String, dynamic> projectData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token == null) {
        throw Exception('Authentication token not found. Please login again.');
      }

      final url = await baseUrl;
      final response = await http.post(
        Uri.parse('$url/projects'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: jsonEncode(projectData),
      );

      if (response.statusCode != 201) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to create project');
      }
    } catch (e) {
      print('Error in createProject: $e');
      if (e is Exception) {
        throw e;
      }
      throw Exception('Failed to create project. Please try again.');
    }
  }

  Future<List<Map<String, dynamic>>> getProjects() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token == null) {
        throw Exception('Authentication token not found. Please login again.');
      }

      final url = await baseUrl;
      final response = await http.get(
        Uri.parse('$url/projects'),
        headers: {
          'Authorization': 'Bearer $token'
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((project) => {
          'projectId': project['projectId'] as String,
          'title': project['title'] as String,
          'description': project['description'] as String?,
          'maxGroups': project['maxGroups'] as int,
          'minMembers': project['minMembers'] as int,
          'maxMembers': project['maxMembers'] as int,
          'createdAt': project['createdAt'] as String,
        }).toList();
      } else {
        throw Exception('Failed to fetch projects');
      }
    } catch (e) {
      print('Error in getProjects: $e');
      if (e is Exception) {
        throw e;
      }
      throw Exception('Failed to fetch projects. Please try again.');
    }
  }

  Future<List<Map<String, dynamic>>> getProjectForms() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token == null) {
        throw Exception('Authentication token not found. Please login again.');
      }

      print('Fetching project forms...');
      print('Using token: $token');
      
      final url = await baseUrl;
      final response = await http.get(
        Uri.parse('$url/project-forms'),
        headers: {
          'Authorization': 'Bearer $token'
        },
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        print('Parsed response data: $responseData');
        
        if (responseData['success'] == true && responseData['data'] != null) {
          final List<dynamic> forms = responseData['data'];
          print('Found ${forms.length} forms');
          return forms.map((form) => form as Map<String, dynamic>).toList();
        } else {
          print('Invalid response format: $responseData');
          throw Exception(responseData['message'] ?? 'Invalid response format');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to fetch project forms: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getProjectForms: $e');
      if (e is Exception) {
        throw e;
      }
      throw Exception('Failed to fetch project forms. Please try again.');
    }
  }

  Future<void> createProjectForm(Map<String, dynamic> formData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token == null) {
        throw Exception('Authentication token not found. Please login again.');
      }

      final url = await baseUrl;
      final response = await http.post(
        Uri.parse('$url/project-forms'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: jsonEncode({
          'year': formData['year'],
          'formName': formData['formName'],
          'projects': formData['projects'],
          'startDate': formData['startDate'],
          'endDate': formData['endDate'],
        }),
      );

      if (response.statusCode != 201) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to create project form');
      }
    } catch (e) {
      print('Error in createProjectForm: $e');
      throw Exception('Failed to create project form. Please try again.');
    }
  }

  Future<Map<String, dynamic>> toggleProjectFormStatus(String formId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token == null) {
        throw Exception('Authentication token not found. Please login again.');
      }

      final url = await baseUrl;
      print('Toggling form status for formId: $formId');
      final response = await http.patch(
        Uri.parse('$url/project-forms/$formId/toggle'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      // Detect HTML error (e.g. <!DOCTYPE html>)
      if (response.headers['content-type']?.contains('text/html') == true || response.body.trim().startsWith('<!DOCTYPE')) {
        print('Received HTML response instead of JSON.');
        throw Exception('Server error: Received HTML instead of JSON. Possible wrong API URL or server error.');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        try {
          final errorData = jsonDecode(response.body);
          throw Exception(errorData['message'] ?? 'Failed to toggle project form status');
        } catch (e) {
          throw Exception('Failed to toggle project form status. Invalid server response.');
        }
      }
    } catch (e) {
      print('Error in toggleProjectFormStatus: $e');
      if (e is Exception) {
        throw e;
      }
      throw Exception('Failed to toggle project form status. Please try again.');
    }
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token == null) {
        print('No auth token found in SharedPreferences');
        throw Exception('Authentication token not found. Please login again.');
      }

      print('Making request to getCurrentUser with token: ${token.substring(0, 10)}...');
      
      final url = await baseUrl;
      final response = await http.get(
        Uri.parse('$url/auth/me'),
        headers: {
          'Authorization': 'Bearer $token'
        },
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Parsed response data: $data');
        
        if (data['success'] == true && data['user'] != null) {
          return {'user': data['user']};
        } else {
          print('Invalid response format: $data');
          throw Exception(data['message'] ?? 'Invalid response format');
        }
      } else if (response.statusCode == 401) {
        print('Authentication failed with status 401');
        throw Exception('Authentication failed. Please login again.');
      } else {
        final errorData = jsonDecode(response.body);
        print('Error response: $errorData');
        throw Exception(errorData['message'] ?? 'Failed to get user details');
      }
    } catch (e) {
      print('Error in getCurrentUser: $e');
      if (e is FormatException) {
        print('JSON parsing error: $e');
        throw Exception('Invalid server response format');
      }
      throw Exception('Failed to get user details. Please try again.');
    }
  }

  Future<void> registerProjectGroup(Map<String, dynamic> groupData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token == null) {
        throw Exception('Authentication token not found. Please login again.');
      }

      // Validate student IDs before sending
      final teamLeader = groupData['teamLeader'] as String;
      final teamMembers = List<String>.from(groupData['teamMembers'] ?? []);

      // Validate team leader ID format
      if (!RegExp(r'^STU\d{3}$').hasMatch(teamLeader.toUpperCase())) {
        throw Exception('Invalid team leader ID format. Must be in format STU001');
      }

      // Validate team member IDs format
      for (var id in teamMembers) {
        if (!RegExp(r'^STU\d{3}$').hasMatch(id.toUpperCase())) {
          throw Exception('Invalid team member ID format. Must be in format STU001');
        }
      }

      final url = await baseUrl;
      print('Registering project group with data: $groupData');
      print('Sending request to: $url/project-groups/register');
      print('Headers: ${{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      }}');
      
      final response = await http.post(
        Uri.parse('$url/project-groups/register'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: jsonEncode(groupData),
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          print('Project group registered successfully');
          return;
        } else {
          throw Exception(responseData['message'] ?? 'Failed to register project group');
        }
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Invalid request');
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else if (response.statusCode == 404) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Project or form not found');
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to register project group');
      }
    } catch (e) {
      print('Error in registerProjectGroup: $e');
      print('Stack trace: ${StackTrace.current}');
      if (e is FormatException) {
        throw Exception('Invalid student ID format. Please check the student ID.');
      }
      if (e is Exception) {
        throw e;
      }
      throw Exception('Failed to register project group. Please try again.');
    }
  }

  Future<Map<String, dynamic>> deleteProjectForm(String formId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token == null) {
        throw Exception('Authentication token not found. Please login again.');
      }

      final url = await baseUrl;
      final response = await http.delete(
        Uri.parse('$url/project-forms/$formId'),
        headers: {
          'Authorization': 'Bearer $token'
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to delete project form');
      }
    } catch (e) {
      print('Error in deleteProjectForm: $e');
      if (e is Exception) {
        throw e;
      }
      throw Exception('Failed to delete project form. Please try again.');
    }
  }

  Future<Map<String, dynamic>> getRegistrationStatus(String formId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token == null) {
        throw Exception('Authentication token not found. Please login again.');
      }

      final url = await baseUrl;
      final response = await http.get(
        Uri.parse('$url/project-groups/registration-status/$formId'),
        headers: {
          'Authorization': 'Bearer $token'
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? {};
      } else if (response.statusCode == 404) {
        return {
          'registered': [],
          'unregistered': []
        };
      } else {
        throw Exception('Failed to fetch registration status');
      }
    } catch (e) {
      print('Error in getRegistrationStatus: $e');
      throw Exception('Failed to fetch registration status. Please try again.');
    }
  }

  Future<void> deleteProject(String formId, String projectId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token == null) {
        throw Exception('Authentication token not found. Please login again.');
      }

      final url = await baseUrl;
      final response = await http.delete(
        Uri.parse('$url/project-forms/$formId/projects/$projectId'),
        headers: {
          'Authorization': 'Bearer $token'
        },
      );

      if (response.statusCode != 200) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to delete project');
      }
    } catch (e) {
      print('Error in deleteProject: $e');
      if (e is Exception) {
        throw e;
      }
      throw Exception('Failed to delete project. Please try again.');
    }
  }

  Future<void> updateProject(String projectId, Map<String, dynamic> projectData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token == null) {
        throw Exception('Authentication token not found. Please login again.');
      }

      final url = await baseUrl;
      final response = await http.put(
        Uri.parse('$url/projects/$projectId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: jsonEncode(projectData),
      );

      if (response.statusCode != 200) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to update project');
      }
    } catch (e) {
      print('Error in updateProject: $e');
      if (e is Exception) {
        throw e;
      }
      throw Exception('Failed to update project. Please try again.');
    }
  }

  Future<void> softDeleteProject(String projectId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token == null) {
        throw Exception('Authentication token not found. Please login again.');
      }

      final url = await baseUrl;
      final response = await http.delete(
        Uri.parse('$url/projects/$projectId'),
        headers: {
          'Authorization': 'Bearer $token'
        },
      );

      if (response.statusCode != 200) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to delete project');
      }
    } catch (e) {
      print('Error in softDeleteProject: $e');
      if (e is Exception) {
        throw e;
      }
      throw Exception('Failed to delete project. Please try again.');
    }
  }

  Future<Map<String, dynamic>> getStudentsByFormId(String formId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token == null) {
        throw Exception('Authentication token not found. Please login again.');
      }

      final url = await baseUrl;
      final response = await http.get(
        Uri.parse('$url/project-groups/students/$formId'),
        headers: {
          'Authorization': 'Bearer $token'
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return data['data'];
        }
        throw Exception(data['message']);
      }
      throw Exception('Failed to fetch form details');
    } catch (e) {
      throw Exception('Error fetching form details: $e');
    }
  }

  Future<Map<String, dynamic>> getStudentsByFormName(String formName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token == null) {
        throw Exception('Authentication token not found. Please login again.');
      }

      final url = await baseUrl;
      final response = await http.get(
        Uri.parse('$url/project-groups/students/by-name/${Uri.encodeComponent(formName)}'),
        headers: {
          'Authorization': 'Bearer $token'
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return data['data'];
        }
        throw Exception(data['message']);
      } else if (response.statusCode == 404) {
        throw Exception('Form not found');
      }
      throw Exception('Failed to fetch form details');
    } catch (e) {
      throw Exception('Error fetching form details: $e');
    }
  }

  Future<List<int>> downloadFormRegistrations(String formName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token == null) {
        throw Exception('Authentication token not found. Please login again.');
      }

      final url = await baseUrl;
      final response = await http.get(
        Uri.parse('$url/form-registrations/download/$formName'),
        headers: {
          'Accept': 'text/csv',
          'Authorization': 'Bearer $token'
        },
      );

      if (response.statusCode != 200) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to download form registrations');
      }

      // Get the file name from the response headers (we'll use this in the calling code)
      final contentDisposition = response.headers['content-disposition'];
      String fileName = '${formName}_registrations.csv';
      if (contentDisposition != null) {
        final match = RegExp(r'filename=(.+)').firstMatch(contentDisposition);
        if (match != null) {
          fileName = match.group(1)!;
        }
      }

      // Convert response body to bytes if it's not already and return them
      final bytes = response.bodyBytes;
      return bytes;
    } catch (e) {
      print('Error downloading form registrations: $e');
      throw Exception('Failed to download form registrations: $e');
    }
  }
  
  // Helper method to save files to device
  Future<String> saveFileToDevice(List<int> bytes, String fileName) async {
    if (kIsWeb) {
      // Web-specific download handling
      try {
        // Create a blob with the correct MIME type
        final blob = html.Blob([bytes], 'text/csv');
        
        // Create object URL and trigger download
        final downloadUrl = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: downloadUrl)
          ..setAttribute('download', fileName)
          ..style.display = 'none';
        
        html.document.body?.append(anchor);
        anchor.click();
        anchor.remove();
        html.Url.revokeObjectUrl(downloadUrl);
        return 'Downloaded to your browser';
      } catch (e) {
        print('Error in web download: $e');
        throw Exception('Failed to download on web platform: $e');
      }
    } else {
      try {
        // For Android devices
        if (io.Platform.isAndroid) {
          // We're skipping permission checks here since we request them at app startup
          
          // Get the external storage directory path
          String? externalStoragePath;
          
          try {
            // Try to access the external storage directory directly
            final externalDir = await path_provider.getExternalStorageDirectory();
            if (externalDir != null) {
              // Navigate to the root of external storage by going up the path
              final pathParts = externalDir.path.split('/');
              int androidIndex = pathParts.indexOf('Android');
              
              if (androidIndex != -1 && androidIndex > 0) {
                // Go up to the parent of Android directory (this is the root of external storage)
                externalStoragePath = pathParts.sublist(0, androidIndex).join('/');
                
                // Create a direct path to the Download folder
                final downloadPath = '$externalStoragePath/Download';
                final downloadDir = io.Directory(downloadPath);
                
                // Create the Download directory if it doesn't exist
                if (!await downloadDir.exists()) {
                  await downloadDir.create(recursive: true);
                }
                
                // Save the file directly to the Download folder
                final filePath = '$downloadPath/$fileName';
                final file = io.File(filePath);
                await file.writeAsBytes(bytes);
                print('File saved directly to device Download folder: $filePath');
                return filePath;
              }
            }
          } catch (e) {
            print('Error accessing root external storage: $e');
          }
          
          // If we couldn't access the root Download folder, try the app's external storage
          try {
            final externalDir = await path_provider.getExternalStorageDirectory();
            if (externalDir != null) {
              // Create a Download directory in the app's external storage area
              final downloadDir = io.Directory('${externalDir.path}/Download');
              if (!await downloadDir.exists()) {
                await downloadDir.create(recursive: true);
              }
              
              final filePath = '${downloadDir.path}/$fileName';
              final file = io.File(filePath);
              await file.writeAsBytes(bytes);
              print('File saved to app external storage: $filePath');
              return filePath;
            }
          } catch (e) {
            print('Error accessing app external storage: $e');
          }
          
          // Last resort: save to app's documents directory
          final directory = await path_provider.getApplicationDocumentsDirectory();
          final downloadsDir = io.Directory('${directory.path}/Downloads');
          if (!await downloadsDir.exists()) {
            await downloadsDir.create(recursive: true);
          }
          
          final filePath = '${downloadsDir.path}/$fileName';
          final file = io.File(filePath);
          await file.writeAsBytes(bytes);
          print('File saved to app documents directory: $filePath');
          return filePath;
        } 
        // For iOS
        else if (io.Platform.isIOS) {
          final directory = await path_provider.getApplicationDocumentsDirectory();
          final downloadsDir = io.Directory('${directory.path}/Downloads');
          if (!await downloadsDir.exists()) {
            await downloadsDir.create(recursive: true);
          }
          
          final filePath = '${downloadsDir.path}/$fileName';
          final file = io.File(filePath);
          
          // Write the bytes to the file
          await file.writeAsBytes(bytes);
          
          print('File saved successfully to: $filePath');
          return filePath;
        }
        
        throw Exception('Unsupported platform');
      } catch (e) {
        print('Error saving file on mobile: $e');
        throw Exception('Failed to save file on mobile: $e');
      }
    }
  }
  
  // Method to save attendance data to file
  Future<String> saveAttendanceToFile(List<int> bytes, String fileName) async {
    return await saveFileToDevice(bytes, fileName);
  }
  
  // Method to open a file after downloading
  Future<void> openDownloadedFile(String filePath) async {
    try {
      final result = await OpenFile.open(filePath);
      print('File open result: ${result.message}');
      if (result.type != ResultType.done) {
        throw Exception('Could not open file: ${result.message}');
      }
    } catch (e) {
      print('Error opening file: $e');
      throw Exception('Failed to open file: $e');
    }
  }
  
  // Helper method to get downloads directory
  Future<io.Directory> getDownloadsDirectory() async {
    if (io.Platform.isAndroid) {
      // For Android, try to use external storage first
      try {
        final externalDir = await path_provider.getExternalStorageDirectory();
        if (externalDir != null) {
          // Create a Download directory in the external storage
          final downloadDir = io.Directory('${externalDir.path}/Download');
          if (!await downloadDir.exists()) {
            await downloadDir.create(recursive: true);
          }
          print('Using external storage Download directory: ${downloadDir.path}');
          return downloadDir;
        }
      } catch (e) {
        print('Error accessing external storage: $e');
      }
      
      // Fallback to app's documents directory
      final directory = await path_provider.getApplicationDocumentsDirectory();
      final downloadsDir = io.Directory('${directory.path}/Downloads');
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }
      print('Using app-specific Downloads directory: ${downloadsDir.path}');
      return downloadsDir;
    } else {
      // For iOS and other platforms
      final directory = await path_provider.getApplicationDocumentsDirectory();
      final downloadsDir = io.Directory('${directory.path}/Downloads');
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }
      return downloadsDir;
    }
  }
  
  // Helper method to get application documents directory
  Future<io.Directory> getApplicationDocumentsDirectory() async {
    return await path_provider.getApplicationDocumentsDirectory();
  }
}
