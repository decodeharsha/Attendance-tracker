import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/api_service.dart';

class ProjectRegistrationScreen extends StatefulWidget {
  final Map<String, dynamic> project;
  final String formId;
  final int projectIndex;

  const ProjectRegistrationScreen({
    Key? key,
    required this.project,
    required this.formId,
    required this.projectIndex,
  }) : super(key: key);

  @override
  _ProjectRegistrationScreenState createState() => _ProjectRegistrationScreenState();
}

class _ProjectRegistrationScreenState extends State<ProjectRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _teamLeaderController = TextEditingController();
  final List<TextEditingController> _teamMemberControllers = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Initialize team member controllers based on minMembers
    for (int i = 0; i < widget.project['minMembers'] - 1; i++) {
      _teamMemberControllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    _teamLeaderController.dispose();
    for (var controller in _teamMemberControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addTeamMember() {
    if (_teamMemberControllers.length < widget.project['maxMembers'] - 1) {
      setState(() {
        _teamMemberControllers.add(TextEditingController());
      });
    }
  }

  void _removeTeamMember() {
    if (_teamMemberControllers.length > widget.project['minMembers'] - 1) {
      setState(() {
        _teamMemberControllers.last.dispose();
        _teamMemberControllers.removeLast();
      });
    }
  }

  Future<void> _registerGroup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('Starting group registration...');
      print('Form ID: ${widget.formId}');
      print('Project Index: ${widget.projectIndex}');
      print('Project Details: ${widget.project}');
      print('Team Leader: ${_teamLeaderController.text}');
      print('Team Members: ${_teamMemberControllers.map((c) => c.text).toList()}');

      // Validate student IDs
      final teamLeaderId = _teamLeaderController.text.toUpperCase().trim();
      final teamMemberIds = _teamMemberControllers.map((c) => c.text.toUpperCase().trim()).toList();

      // Validate team leader ID format
      if (!RegExp(r'^STU\d{3}$').hasMatch(teamLeaderId)) {
        throw Exception('Invalid team leader ID format. Must be in format STU001');
      }

      // Validate team member IDs format
      for (var id in teamMemberIds) {
        if (!RegExp(r'^STU\d{3}$').hasMatch(id)) {
          throw Exception('Invalid team member ID format. Must be in format STU001');
        }
      }

      final groupData = {
        'formId': widget.formId,
        'projectIndex': widget.projectIndex,
        'teamLeader': teamLeaderId,
        'teamMembers': teamMemberIds,
        'projectId': widget.project['projectId'],
      };

      print('Sending group data: $groupData');

      await ApiService().registerProjectGroup(groupData);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Project group registered successfully')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('Error registering group: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Register Project Group'),
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
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.project['title'],
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                widget.project['description'] ?? 'No description available',
                                style: TextStyle(
                                  color: themeProvider.isDarkMode
                                      ? Colors.white70
                                      : Colors.black54,
                                ),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Team Size: ${widget.project['minMembers']}-${widget.project['maxMembers']} members',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 24),
                      Text(
                        'Team Leader',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      TextFormField(
                        controller: _teamLeaderController,
                        decoration: InputDecoration(
                          labelText: 'Student ID',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter team leader ID';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Team Members',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(Icons.remove_circle_outline),
                                onPressed: _removeTeamMember,
                                color: _teamMemberControllers.length > widget.project['minMembers'] - 1
                                    ? Colors.red
                                    : Colors.grey,
                              ),
                              IconButton(
                                icon: Icon(Icons.add_circle_outline),
                                onPressed: _addTeamMember,
                                color: _teamMemberControllers.length < widget.project['maxMembers'] - 1
                                    ? Colors.green
                                    : Colors.grey,
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      ..._teamMemberControllers.asMap().entries.map((entry) {
                        final index = entry.key;
                        final controller = entry.value;
                        return Padding(
                          padding: EdgeInsets.only(bottom: 16),
                          child: TextFormField(
                            controller: controller,
                            decoration: InputDecoration(
                              labelText: 'Team Member ${index + 1} ID',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter team member ID';
                              }
                              return null;
                            },
                          ),
                        );
                      }).toList(),
                      SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _registerGroup,
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Register Group',
                            style: TextStyle(fontSize: 16),
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