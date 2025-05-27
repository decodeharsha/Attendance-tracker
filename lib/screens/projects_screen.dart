import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/api_service.dart';
import 'create_project_screen.dart';

class ProjectsScreen extends StatefulWidget {
  @override
  _ProjectsScreenState createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _projects = [];

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final projects = await ApiService().getProjects();
      setState(() {
        _projects = projects;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load projects'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _editProject(Map<String, dynamic> project) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateProjectScreen(
          isEditMode: true,
          project: project,
        ),
      ),
    );

    if (result == true) {
      _loadProjects();
    }
  }

  Future<void> _deleteProject(String projectId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Project'),
        content: Text('Are you sure you want to delete this project?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ApiService().softDeleteProject(projectId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Project deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadProjects();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete project'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Projects'),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => CreateProjectScreen()),
          );
          _loadProjects();
        },
        child: Icon(Icons.add),
        tooltip: 'Create New Project',
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
            : _projects.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.folder_open,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No projects yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Click the + button to create a project',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadProjects,
                    child: ListView.builder(
                      padding: EdgeInsets.all(16),
                      itemCount: _projects.length,
                      itemBuilder: (context, index) {
                        final project = _projects[index];
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
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            project['title'],
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            'Project ID: ${project['projectId']}',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.edit),
                                      onPressed: () => _editProject(project),
                                      tooltip: 'Edit Project',
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete),
                                      onPressed: () => _deleteProject(project['projectId']),
                                      tooltip: 'Delete Project',
                                      color: Colors.red,
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Text(
                                  project['description'] ?? 'No description available',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                  ),
                                ),
                                SizedBox(height: 8),
                                Row(
                                  children: [
                                    _buildInfoChip(
                                      'Max Groups: ${project['maxGroups']}',
                                      Icons.group,
                                    ),
                                    SizedBox(width: 8),
                                    _buildInfoChip(
                                      'Team Size: ${project['minMembers']}-${project['maxMembers']}',
                                      Icons.people,
                                    ),
                                  ],
                                ),
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

  Widget _buildInfoChip(String label, IconData icon) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(
        label,
        style: TextStyle(fontSize: 12),
      ),
      backgroundColor: Colors.grey[200],
    );
  }
} 