import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/api_service.dart';
import 'project_selection_screen.dart';

class ProjectFormScreen extends StatefulWidget {
  @override
  _ProjectFormScreenState createState() => _ProjectFormScreenState();
}

class _ProjectFormScreenState extends State<ProjectFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _yearController = TextEditingController();
  final _formNameController = TextEditingController();
  List<Map<String, dynamic>> _selectedProjects = [];
  bool _isLoading = false;
  List<Map<String, dynamic>> _forms = [];
  DateTime? _startDate;
  DateTime? _endDate;
  Map<String, Map<String, dynamic>> _registrationStatus = {};
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _loadForms();
  }

  @override
  void dispose() {
    _yearController.dispose();
    _formNameController.dispose();
    super.dispose();
  }

  Future<void> _loadUserRole() async {
    try {
      final userData = await ApiService().getCurrentUser();
      print('User data received: $userData'); // Debug log
      setState(() {
        _userRole = userData['role'];
      });
      print('User role set to: $_userRole'); // Debug log
    } catch (e) {
      print('Error loading user role: $e');
      // Set a default role if there's an error
      setState(() {
        _userRole = 'admin';
      });
    }
  }

  Future<void> _loadForms() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final forms = await ApiService().getProjectForms();
      
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load project forms'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _createForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select at least one project'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select both start and end dates'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_endDate!.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('End date must be after start date'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('Creating form with year: ${_yearController.text}');
      print('Form name: ${_formNameController.text}');
      print('Selected projects: $_selectedProjects');
      print('Start date: $_startDate');
      print('End date: $_endDate');

      final formData = {
        'year': int.parse(_yearController.text),
        'formName': _formNameController.text,
        'projects': _selectedProjects.map((project) => {
          'projectId': project['projectId'],
          'title': project['title'],
          'description': project['description'],
          'maxGroups': project['maxGroups'],
          'minMembers': project['minMembers'],
          'maxMembers': project['maxMembers'],
        }).toList(),
        'startDate': _startDate!.toIso8601String(),
        'endDate': _endDate!.toIso8601String(),
      };

      await ApiService().createProjectForm(formData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Project form created successfully'),
          backgroundColor: Colors.green,
        ),
      );

      _yearController.clear();
      _formNameController.clear();
      _selectedProjects.clear();
      _startDate = null;
      _endDate = null;
      _loadForms();
    } catch (e) {
      print('Error creating form: $e');
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

  Future<void> _toggleFormStatus(String formId) async {
    try {
      setState(() {
        _isLoading = true;
      });

      print('Toggling form status for formId: $formId');
      final response = await ApiService().toggleProjectFormStatus(formId);
      print('Toggle response: $response');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message'] ?? 'Form status updated successfully'),
          backgroundColor: Colors.green,
        ),
      );

      // Refresh the forms list
      await _loadForms();
    } catch (e) {
      print('Error toggling form status: $e');
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

  Future<void> _deleteForm(String formId) async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Show confirmation dialog
      final shouldDelete = await showDialog<bool>(
        context: context,
        builder: (context) {
          final screenWidth = MediaQuery.of(context).size.width;
          final dialogWidth = screenWidth * 0.85;
          return AlertDialog(
            title: Text('Delete Form'),
            content: Container(
              width: dialogWidth,
              constraints: BoxConstraints(
                maxWidth: dialogWidth,
                minWidth: 200,
              ),
              child: SingleChildScrollView(
                child: Text('Are you sure you want to delete this form? This action cannot be undone.'),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          );
        },
      );

      if (shouldDelete != true) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      await ApiService().deleteProjectForm(formId);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Form deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );

      // Refresh the forms list
      await _loadForms();
    } catch (e) {
      print('Error deleting form: $e');
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

  Widget _buildRegistrationStatus(String formId) {
    final status = _registrationStatus[formId];
    if (status == null) return SizedBox.shrink();

    // Get the actual lists of registered and unregistered students
    final registeredStudents = List<Map<String, dynamic>>.from(status['registered'] ?? []);
    final unregisteredStudents = List<Map<String, dynamic>>.from(status['unregistered'] ?? []);
    
    final registeredCount = registeredStudents.length;
    final unregisteredCount = unregisteredStudents.length;
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
          if (registeredCount > 0) ...[
            SizedBox(height: 8),
            Text(
              'Registered Students:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: registeredStudents.map((student) => Chip(
                label: Text(student['studentId']),
                backgroundColor: Colors.green.shade100,
                labelStyle: TextStyle(color: Colors.green.shade900),
              )).toList(),
            ),
          ],
          if (unregisteredCount > 0) ...[
            SizedBox(height: 8),
            Text(
              'Unregistered Students:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: unregisteredStudents.map((student) => Chip(
                label: Text(student['studentId']),
                backgroundColor: Colors.red.shade100,
                labelStyle: TextStyle(color: Colors.red.shade900),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProjectCard(Map<String, dynamic> project, String formId) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(project['title']),
        subtitle: Text(
          'Max Groups: ${project['maxGroups']}\n'
          'Team Size: ${project['minMembers']}-${project['maxMembers']} members',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    print('Building screen with user role: $_userRole'); // Debug log

    return Scaffold(
      appBar: AppBar(
        title: Text('Project Forms'),
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
            : SingleChildScrollView(
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
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Create New Form',
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
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a form name';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 16),
                              TextFormField(
                                controller: _yearController,
                                decoration: InputDecoration(
                                  labelText: 'Year',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a year';
                                  }
                                  if (int.tryParse(value) == null) {
                                    return 'Please enter a valid year';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextButton.icon(
                                      onPressed: () => _selectDate(context, true),
                                      icon: Icon(Icons.calendar_today),
                                      label: Text(_startDate == null
                                          ? 'Select Start Date'
                                          : 'Start: ${_startDate!.toString().split(' ')[0]}'),
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: TextButton.icon(
                                      onPressed: () => _selectDate(context, false),
                                      icon: Icon(Icons.calendar_today),
                                      label: Text(_endDate == null
                                          ? 'Select End Date'
                                          : 'End: ${_endDate!.toString().split(' ')[0]}'),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () async {
                                  final projects = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ProjectSelectionScreen(),
                                    ),
                                  );
                                  if (projects != null) {
                                    setState(() {
                                      _selectedProjects = projects;
                                    });
                                  }
                                },
                                child: Text('Select Projects'),
                              ),
                              SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: _createForm,
                                  child: Text('Create Form'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    Text(
                      'Existing Forms',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    if (_forms.isEmpty)
                      Center(
                        child: Text(
                          'No forms created yet',
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
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
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        form['formName'] ?? 'Unnamed Form',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Switch(
                                            value: form['isActive'],
                                            onChanged: (value) {
                                              _toggleFormStatus(form['_id']);
                                            },
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.delete, color: Colors.red),
                                            onPressed: () => _deleteForm(form['_id']),
                                            tooltip: 'Delete Form',
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
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
                                    'Projects:',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  ...form['projects'].map<Widget>((project) => _buildProjectCard(project, form['_id'])).toList(),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
      ),
    );
  }
} 