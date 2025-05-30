import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/api_service.dart';
import 'project_registration_screen.dart';

class StudentFormsScreen extends StatefulWidget {
  @override
  _StudentFormsScreenState createState() => _StudentFormsScreenState();
}

class _StudentFormsScreenState extends State<StudentFormsScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _forms = [];
  Map<String, Map<String, dynamic>> _registrationStatus = {};

  @override
  void initState() {
    super.initState();
    _loadForms();
  }

  Future<void> _loadForms() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('Loading project forms...');
      final forms = await ApiService().getProjectForms();
      print('Received forms: ${forms.length}');
      
      if (forms.isEmpty) {
        print('No forms received from the server');
      } else {
        forms.forEach((form) {
          print('Form details:');
          print('- ID: ${form['_id']}');
          print('- Year: ${form['year']}');
          print('- Is Active: ${form['isActive']}');
          print('- Released By: ${form['releasedBy']['name']}');
          print('- Projects: ${form['projects'].length}');
          form['projects'].forEach((project) {
            print('  Project: ${project['title']} (${project['projectId']})');
          });
        });
      }
      
      // Load registration status for each form
      for (var form in forms) {
        try {
          final status = await ApiService().getRegistrationStatus(form['_id']);
          _registrationStatus[form['_id']] = status;
        } catch (e) {
          print('Error loading registration status for form ${form['_id']}: $e');
        }
      }
      
      setState(() {
        _forms = forms;
      });
    } catch (e) {
      print('Error loading forms: $e');
      String errorMessage = 'Failed to load project forms';
      
      if (e.toString().contains('Authentication failed')) {
        errorMessage = 'Please login again to view project forms';
      } else if (e.toString().contains('token not found')) {
        errorMessage = 'Please login again to view project forms';
      } else if (e.toString().contains('Student year information not found')) {
        errorMessage = 'Student information is incomplete. Please contact support.';
      } else if (e.toString().contains('Invalid response format')) {
        errorMessage = 'Server returned invalid data. Please try again.';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: _loadForms,
            textColor: Colors.white,
          ),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildRegistrationStatus(String formId) {
    final status = _registrationStatus[formId];
    if (status == null) return SizedBox.shrink();

    final registeredCount = status['registered']?.length ?? 0;
    final unregisteredCount = status['unregistered']?.length ?? 0;
    final totalCount = registeredCount + unregisteredCount;

    return Container(
      margin: EdgeInsets.only(top: 8),
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Registration Status:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Registered: $registeredCount students',
                  style: TextStyle(color: Colors.green),
                ),
              ),
              Expanded(
                child: Text(
                  'Unregistered: $unregisteredCount students',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          LinearProgressIndicator(
            value: totalCount > 0 ? registeredCount / totalCount : 0,
            backgroundColor: Colors.red.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Available Project Forms'),
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
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : _forms.isEmpty
                ? Center(
                    child: Text(
                      'No active project forms available',
                      style: TextStyle(
                        fontSize: 18,
                        color: themeProvider.isDarkMode
                            ? Colors.white70
                            : Colors.black54,
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadForms,
                    child: ListView.builder(
                      padding: EdgeInsets.all(16),
                      itemCount: _forms.length,
                      itemBuilder: (context, index) {
                        final form = _forms[index];
                        return Card(
                          elevation: 4,
                          margin: EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  form['formName'] ?? 'Unnamed Form',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Year ${form['year']}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: themeProvider.isDarkMode
                                        ? Colors.white70
                                        : Colors.black54,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Released by: ${form['releasedBy']['name']}',
                                  style: TextStyle(
                                    color: themeProvider.isDarkMode
                                        ? Colors.white70
                                        : Colors.black54,
                                  ),
                                ),
                                _buildRegistrationStatus(form['_id']),
                                SizedBox(height: 16),
                                Text(
                                  'Available Projects:',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 8),
                                ...form['projects'].map<Widget>((project) {
                                  // Calculate available slots
                                  final int maxGroups = project['maxGroups'] ?? 0;
                                  final int registeredGroups = project['registeredGroups'] ?? 0;
                                  final int availableSlots = maxGroups - registeredGroups;
                                  return Card(
                                    margin: EdgeInsets.only(bottom: 8),
                                    child: ListTile(
                                      title: Text(project['title']),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Max Groups: $maxGroups\nTeam Size: ${project['minMembers']}-${project['maxMembers']} members',
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            'Available Slots: $availableSlots',
                                            style: TextStyle(
                                              color: availableSlots > 0 ? Colors.green : Colors.red,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      trailing: ElevatedButton(
                                        onPressed: availableSlots > 0
                                            ? () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) => ProjectRegistrationScreen(
                                                      project: project,
                                                      formId: form['_id'],
                                                      projectIndex: form['projects'].indexOf(project),
                                                    ),
                                                  ),
                                                ).then((registered) {
                                                  if (registered == true) {
                                                    _loadForms(); // Refresh the forms list
                                                  }
                                                });
                                              }
                                            : null, // Disable the button if no slots
                                        child: Text('Register'),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
      ),
    );
  }
} 