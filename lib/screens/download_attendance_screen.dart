import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' as io;
import 'package:permission_handler/permission_handler.dart';

// Use conditional imports
// For web platform - using universal_html for better compatibility
import 'package:universal_html/html.dart' as html
    if (dart.library.io) 'dart:ui';

class DownloadAttendanceScreen extends StatefulWidget {
  @override
  _DownloadAttendanceScreenState createState() => _DownloadAttendanceScreenState();
}

class _DownloadAttendanceScreenState extends State<DownloadAttendanceScreen> {
  final _projectIdController = TextEditingController();
  DateTime? _selectedDate;
  bool _isLoading = false;

  List<Map<String, dynamic>> _projects = [];
  List<Map<String, dynamic>> _filteredProjects = [];
  String? _selectedProjectId;
  bool _isLoadingProjects = false;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() {
      _isLoadingProjects = true;
    });
    try {
      final projects = await ApiService().getProjects();
      setState(() {
        _projects = projects;
        _filteredProjects = projects;
        _isLoadingProjects = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingProjects = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load projects'), backgroundColor: Colors.red),
      );
    }
  }

  void _filterProjects(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredProjects = _projects;
      } else {
        _filteredProjects = _projects.where((project) {
          final projectId = project['projectId'].toString().toLowerCase();
          final title = project['title'].toString().toLowerCase();
          final searchQuery = query.toLowerCase();
          return projectId.contains(searchQuery) || title.contains(searchQuery);
        }).toList();
      }
    });
  }

  void _handleProjectIdChange(String value) {
    _filterProjects(value);
    setState(() {
      _selectedProjectId = value.trim();
    });
  }

  @override
  void dispose() {
    _projectIdController.dispose();
    super.dispose();
  }

  Future<void> _downloadAttendance() async {
    final projectId = _selectedProjectId ?? _projectIdController.text;
    if (projectId.isEmpty || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select both project and date'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Permissions are already requested at app startup, so we don't need to check here

      // Format the date to YYYY-MM-DD
      final dateParts = _selectedDate!.toIso8601String().split('T')[0].split('-');
      final formattedDate = '${dateParts[0]}-${dateParts[1]}-${dateParts[2]}';

      final attendanceDetails = await ApiService().getAttendanceDetails(
        projectId,
        formattedDate,
      );

      if (attendanceDetails == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No attendance found for the selected date and project'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Convert attendance data to CSV format
      final csvData = _convertToCSV(attendanceDetails);
      final bytes = utf8.encode(csvData);
      final fileName = 'attendance_${_projectIdController.text}_$formattedDate.csv';

      try {
        if (kIsWeb) {
          // Web platform - use universal_html
          // Create a blob and download the file
          final blob = html.Blob([bytes], 'text/csv');
          final downloadUrl = html.Url.createObjectUrlFromBlob(blob);
          final anchor = html.AnchorElement(href: downloadUrl)
            ..setAttribute('download', fileName)
            ..style.display = 'none';

          html.document.body?.append(anchor);
          anchor.click();
          anchor.remove();
          html.Url.revokeObjectUrl(downloadUrl);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('File downloaded successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          // For mobile platforms - save directly to device's Download folder
          final filePath = await ApiService().saveFileToDevice(bytes, fileName);

          // Show a message with the file location and option to open
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('File downloaded successfully'),
                  Text(
                    'Saved to: $filePath',
                    style: TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 8),
              action: SnackBarAction(
                label: 'OPEN',
                textColor: Colors.white,
                onPressed: () {
                  try {
                    // Open the downloaded file
                    ApiService().openDownloadedFile(filePath);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Could not open file: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
              ),
            ),
          );
        }
      } catch (e) {
        print('Error downloading file: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download file: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to download attendance: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _convertToCSV(Map<String, dynamic> attendanceDetails) {
    final StringBuffer csv = StringBuffer();

    // Add header row
    csv.writeln('Roll Number,Name,Period 1,Period 2,Period 3,Period 4,Period 5,Period 6,Period 7');

    // Track student attendance across periods
    final Map<String, Map<String, dynamic>> studentAttendance = {};

    // Process each period's attendance
    attendanceDetails['periods'].forEach((period, data) {
      // Add present students
      for (var student in data['present']) {
        if (!studentAttendance.containsKey(student['studentId'])) {
          studentAttendance[student['studentId']] = {
            'name': student['name'],
            'periods': List.filled(7, '-'),
          };
        }
        studentAttendance[student['studentId']]!['periods'][int.parse(period) - 1] = 'Present';
      }

      // Add absent students
      for (var student in data['absent']) {
        if (!studentAttendance.containsKey(student['studentId'])) {
          studentAttendance[student['studentId']] = {
            'name': student['name'],
            'periods': List.filled(7, '-'),
          };
        }
        studentAttendance[student['studentId']]!['periods'][int.parse(period) - 1] = 'Absent';
      }
    });

    // Write student attendance data
    studentAttendance.forEach((rollNumber, data) {
      final periods = data['periods'] as List<String>;
      csv.writeln('$rollNumber,${data['name']},${periods.join(',')}');
    });

    return csv.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Download Attendance'),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _isLoadingProjects
                        ? Center(child: CircularProgressIndicator())
                        : Autocomplete<Map<String, dynamic>>(
  optionsBuilder: (TextEditingValue textEditingValue) {
    if (textEditingValue.text.isEmpty) {
      return _projects;
    }
    return _projects.where((project) {
      final projectId = project['projectId'].toString().toLowerCase();
      final title = project['title'].toString().toLowerCase();
      final searchQuery = textEditingValue.text.toLowerCase();
      return projectId.contains(searchQuery) || title.contains(searchQuery);
    });
  },
  displayStringForOption: (option) =>
      '${option['title']} (${option['projectId']})',
  fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      decoration: InputDecoration(
        labelText: 'Project',
        prefixIcon: Icon(Icons.assignment),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  },
  onSelected: (Map<String, dynamic> selection) {
    setState(() {
      _selectedProjectId = selection['projectId'];
      _projectIdController.text = selection['projectId'];
    });
  },
),
                    SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() {
                            _selectedDate = date;
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Date',
                          prefixIcon: Icon(Icons.calendar_today),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          _selectedDate != null
                              ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                              : 'Select Date',
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _downloadAttendance,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text(
                                'Download Attendance',
                                style: TextStyle(fontSize: 16),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}