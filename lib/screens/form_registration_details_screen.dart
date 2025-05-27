import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/api_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' as io;
import 'package:permission_handler/permission_handler.dart';

class FormRegistrationDetailsScreen extends StatefulWidget {
  @override
  _FormRegistrationDetailsScreenState createState() => _FormRegistrationDetailsScreenState();
}

class _FormRegistrationDetailsScreenState extends State<FormRegistrationDetailsScreen> {
  late TextEditingController _formNameController;
  bool _isLoading = false;
  Map<String, dynamic>? _formData;
  List<Map<String, dynamic>> _availableForms = [];

  @override
  void initState() {
    super.initState();
    _formNameController = TextEditingController();
    _loadAvailableForms();
  }

  @override
  void dispose() {
    _formNameController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableForms() async {
    try {
      final forms = await ApiService().getProjectForms();
      setState(() {
        _availableForms = forms;
      });
    } catch (e) {
      print('Error loading forms: $e');
    }
  }

  Future<void> _fetchFormDetails() async {
    if (_formNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a form name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _formData = null;
    });

    try {
      final data = await ApiService().getStudentsByFormName(_formNameController.text);
      setState(() {
        _formData = data;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadRegistrations() async {
    if (_formNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a form name'),
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
      
      // Get the file data and save it
      final fileData = await ApiService().downloadFormRegistrations(_formNameController.text);
      final fileName = 'form_registrations_${_formNameController.text}.csv';
      
      // Show a more detailed success message based on platform
      if (kIsWeb) {
        // For web, trigger a download
        await ApiService().saveFileToDevice(fileData, fileName);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download started'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // For mobile platforms, save directly to the device's Download folder
        final filePath = await ApiService().saveFileToDevice(fileData, fileName);
        
        // Show a detailed message with file location and option to open
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
                  // Open the downloaded file directly
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to download: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // Permission handling is now done at app startup

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Form Registration Details'),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: themeProvider.isDarkMode
                ? [Colors.blue.shade900, Colors.black]
                : [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Search Form',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _formNameController,
                        decoration: InputDecoration(
                          labelText: 'Form Name',
                          border: OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(Icons.search),
                            onPressed: _fetchFormDetails,
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _fetchFormDetails,
                              icon: Icon(Icons.search),
                              label: Text('Search'),
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _downloadRegistrations,
                              icon: Icon(Icons.download),
                              label: Text('Download CSV'),
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                backgroundColor: Colors.green,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),
              if (_isLoading)
                Center(child: CircularProgressIndicator())
              else if (_formData != null)
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFormDetailsCard(),
                        SizedBox(height: 16),
                        _buildProjectsCard(),
                        SizedBox(height: 16),
                        _buildStudentsList('Registered Students', _formData!['registeredStudents']),
                        SizedBox(height: 16),
                        _buildStudentsList('Unregistered Students', _formData!['unregisteredStudents']),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormDetailsCard() {
    final formDetails = _formData!['formDetails'];
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Form Details',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            _buildInfoRow('Form Name', formDetails['formName']),
            _buildInfoRow('Year', formDetails['year'].toString()),
            _buildInfoRow('Total Students', formDetails['totalStudents'].toString()),
            _buildInfoRow('Registered', formDetails['registeredCount'].toString()),
            _buildInfoRow('Unregistered', formDetails['unregisteredCount'].toString()),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectsCard() {
    final projects = _formData!['projects'];
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Projects',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            ...projects.map((project) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  project['title'],
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                _buildInfoRow('Project ID', project['projectId']),
                _buildInfoRow('Registered Groups', '${project['registeredGroups']}/${project['maxGroups']}'),
                SizedBox(height: 16),
              ],
            )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentsList(String title, List<dynamic> students) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            ...students.map((student) => Card(
              margin: EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(student['name']),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ID: ${student['studentId']}'),
                    if (student['isRegistered'] && student['projectId'] != null)
                      Text('Project ID: ${student['projectId']}'),
                  ],
                ),
                trailing: Icon(
                  student['isRegistered'] ? Icons.check_circle : Icons.pending,
                  color: student['isRegistered'] ? Colors.green : Colors.orange,
                ),
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
} 