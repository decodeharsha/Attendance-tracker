import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/api_service.dart';

class ProjectSelectionScreen extends StatefulWidget {
  final int? maxProjects;
  final List<Map<String, dynamic>>? initialSelection;

  const ProjectSelectionScreen({
    Key? key,
    this.maxProjects,
    this.initialSelection,
  }) : super(key: key);

  @override
  _ProjectSelectionScreenState createState() => _ProjectSelectionScreenState();
}

class _ProjectSelectionScreenState extends State<ProjectSelectionScreen> {
  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>> _projects = [];
  List<Map<String, dynamic>> _selectedProjects = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialSelection != null) {
      _selectedProjects = List.from(widget.initialSelection!);
    }
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print('Loading projects...');
      final projects = await ApiService().getProjects();
      print('Projects loaded: ${projects.length}');
      
      if (mounted) {
        setState(() {
          _projects = projects;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading projects: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load projects: ${e.toString()}'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _loadProjects,
            ),
          ),
        );
      }
    }
  }

  void _toggleProjectSelection(Map<String, dynamic> project) {
    setState(() {
      if (_selectedProjects.any((p) => p['projectId'] == project['projectId'])) {
        _selectedProjects.removeWhere((p) => p['projectId'] == project['projectId']);
      } else {
        if (widget.maxProjects != null && _selectedProjects.length >= widget.maxProjects!) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('You can only select up to ${widget.maxProjects} projects'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
        _selectedProjects.add(project);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Select Projects'),
        actions: [
          TextButton(
            onPressed: _selectedProjects.isEmpty
                ? null
                : () {
                    Navigator.pop(context, _selectedProjects);
                  },
            child: Text(
              'Done',
              style: TextStyle(
                color: _selectedProjects.isEmpty ? Colors.white54 : Colors.white,
              ),
            ),
          ),
        ],
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
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Error loading projects',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadProjects,
                          child: Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _projects.isEmpty
                    ? Center(
                        child: Text(
                          'No projects available',
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: _projects.length,
                        itemBuilder: (context, index) {
                          final project = _projects[index];
                          final isSelected = _selectedProjects
                              .any((p) => p['projectId'] == project['projectId']);

                          return Card(
                            elevation: 4,
                            margin: EdgeInsets.only(bottom: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: InkWell(
                              onTap: () => _toggleProjectSelection(project),
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Checkbox(
                                      value: isSelected,
                                      onChanged: (_) => _toggleProjectSelection(project),
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            project['title'] ?? 'Untitled Project',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            project['description'] ?? 'No description available',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.group,
                                                size: 16,
                                                color: Colors.grey[600],
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                '${project['minMembers'] ?? 1}-${project['maxMembers'] ?? 1} members',
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                              SizedBox(width: 16),
                                              Icon(
                                                Icons.category,
                                                size: 16,
                                                color: Colors.grey[600],
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                '${project['maxGroups'] ?? 0} groups max',
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
} 