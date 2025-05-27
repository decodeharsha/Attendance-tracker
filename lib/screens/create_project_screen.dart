import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/api_service.dart';

class CreateProjectScreen extends StatefulWidget {
  final bool isEditMode;
  final Map<String, dynamic>? project;

  CreateProjectScreen({
    this.isEditMode = false,
    this.project,
  });

  @override
  _CreateProjectScreenState createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _projectIdController = TextEditingController();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _maxGroupsController = TextEditingController();
  final _minMembersController = TextEditingController();
  final _maxMembersController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditMode && widget.project != null) {
      _projectIdController.text = widget.project!['projectId'];
      _titleController.text = widget.project!['title'];
      _descriptionController.text = widget.project!['description'] ?? '';
      _maxGroupsController.text = widget.project!['maxGroups'].toString();
      _minMembersController.text = widget.project!['minMembers'].toString();
      _maxMembersController.text = widget.project!['maxMembers'].toString();
    }
  }

  @override
  void dispose() {
    _projectIdController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _maxGroupsController.dispose();
    _minMembersController.dispose();
    _maxMembersController.dispose();
    super.dispose();
  }

  Future<void> _saveProject() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final projectData = {
        'projectId': _projectIdController.text,
        'title': _titleController.text,
        'description': _descriptionController.text,
        'maxGroups': int.parse(_maxGroupsController.text),
        'minMembers': int.parse(_minMembersController.text),
        'maxMembers': int.parse(_maxMembersController.text),
      };

      if (widget.isEditMode) {
        await ApiService().updateProject(widget.project!['projectId'], projectData);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Project updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        await ApiService().createProject(projectData);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Project created successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isEditMode ? 'Failed to update project' : 'Failed to create project'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditMode ? 'Edit Project' : 'Create Project'),
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
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _projectIdController,
                          decoration: InputDecoration(
                            labelText: 'Project ID',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          enabled: !widget.isEditMode,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a project ID';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: _titleController,
                          decoration: InputDecoration(
                            labelText: 'Title',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a title';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: InputDecoration(
                            labelText: 'Description',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          maxLines: 3,
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: _maxGroupsController,
                          decoration: InputDecoration(
                            labelText: 'Maximum Groups',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter maximum groups';
                            }
                            if (int.tryParse(value) == null) {
                              return 'Please enter a valid number';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: _minMembersController,
                          decoration: InputDecoration(
                            labelText: 'Minimum Members per Group',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter minimum members';
                            }
                            if (int.tryParse(value) == null) {
                              return 'Please enter a valid number';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: _maxMembersController,
                          decoration: InputDecoration(
                            labelText: 'Maximum Members per Group',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter maximum members';
                            }
                            if (int.tryParse(value) == null) {
                              return 'Please enter a valid number';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _saveProject,
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: _isLoading
                                ? CircularProgressIndicator(color: Colors.white)
                                : Text(
                                    widget.isEditMode ? 'Update Project' : 'Create Project',
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
        ),
      ),
    );
  }
} 