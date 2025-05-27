import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'student_selection_screen.dart';

class AttendanceMarkingScreen extends StatefulWidget {
  final bool isEditMode;

  AttendanceMarkingScreen({this.isEditMode = false});

  @override
  _AttendanceMarkingScreenState createState() => _AttendanceMarkingScreenState();
}

class _AttendanceMarkingScreenState extends State<AttendanceMarkingScreen> {
  String? _projectId;
  List<int> _selectedPeriods = [];
  List<int> _markedPeriods = [];
  DateTime? _selectedDate;
  bool _isLoading = false;
  final _projectIdController = TextEditingController();
  List<Map<String, dynamic>> _projects = [];
  List<Map<String, dynamic>> _filteredProjects = [];
  bool _isLoadingProjects = false;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  @override
  void dispose() {
    _projectIdController.dispose();
    super.dispose();
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
      print('Error loading projects: $e');
      setState(() {
        _isLoadingProjects = false;
      });
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

  Future<void> _checkMarkedPeriods() async {
    if (_projectId == null || _projectId!.isEmpty || _selectedDate == null) {
      setState(() {
        _markedPeriods = [];
        _selectedPeriods = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Format the date to YYYY-MM-DD
      final dateParts = _selectedDate!.toIso8601String().split('T')[0].split('-');
      final formattedDate = '${dateParts[0]}-${dateParts[1]}-${dateParts[2]}';

      // Check attendance details
      final attendanceDetails = await ApiService().getAttendanceDetails(_projectId!, formattedDate);
      final response = await ApiService().getAttendanceForDate(_projectId!, formattedDate);

      if (response != null && attendanceDetails != null) {
        final markedPeriods = response['markedPeriods'] ?? [];
        final detailsPeriods = attendanceDetails['periods'] ?? {};
        
        // Verify each marked period has actual attendance data
        final verifiedMarkedPeriods = <int>[];
        for (var period in markedPeriods) {
          final periodData = detailsPeriods[period.toString()];
          if (periodData != null && 
              periodData['absent'] != null && 
              periodData['present'] != null &&
              (periodData['absent'].length > 0 || periodData['present'].length > 0)) {
            verifiedMarkedPeriods.add(period);
          }
        }
        
        setState(() {
          _markedPeriods = verifiedMarkedPeriods;
          if (widget.isEditMode) {
            _selectedPeriods = List.from(verifiedMarkedPeriods);
          } else {
            _selectedPeriods.removeWhere((period) => verifiedMarkedPeriods.contains(period));
          }
        });
      } else {
        setState(() {
          _markedPeriods = [];
          if (!widget.isEditMode) {
            _selectedPeriods = [];
          }
        });
      }
    } catch (e) {
      print('Error checking marked periods: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error checking marked periods: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleProjectIdChange(String value) {
    _filterProjects(value);
    final trimmedValue = value.trim();
    setState(() {
      _projectId = trimmedValue;
      _selectedPeriods = [];
      _markedPeriods = [];
    });
    if (_selectedDate != null && trimmedValue.isNotEmpty) {
      _checkMarkedPeriods();
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _selectedPeriods = [];
        _markedPeriods = [];
      });
      if (_projectId != null && _projectId!.isNotEmpty) {
        _checkMarkedPeriods();
      }
    }
  }

  void _proceedToNextScreen() {
    if (_projectId == null || _projectId!.isEmpty || _selectedDate == null || _selectedPeriods.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select date, project ID, and at least one period'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // Format the date to YYYY-MM-DD
    final dateParts = _selectedDate!.toIso8601String().split('T')[0].split('-');
    final formattedDate = '${dateParts[0]}-${dateParts[1]}-${dateParts[2]}';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudentSelectionScreen(
          projectId: _projectId!,
          date: formattedDate,
          periods: _selectedPeriods,
          isEditMode: widget.isEditMode,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditMode ? 'Edit Attendance' : 'Mark Attendance'),
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Loading...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Theme.of(context).primaryColor.withOpacity(0.1),
                    Colors.white,
                  ],
                ),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date Selection Card
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Select Date',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                              SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    _selectedDate?.toString().split(' ')[0] ?? 'No date selected',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: _selectedDate == null ? Colors.grey : Colors.black87,
                                    ),
                                  ),
                                  Spacer(),
                                  ElevatedButton.icon(
                                    onPressed: () => _selectDate(context),
                                    icon: Icon(Icons.edit_calendar),
                                    label: Text('Select'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Theme.of(context).primaryColor,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 20),

                      // Project ID Card
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Project ID',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                              SizedBox(height: 12),
                              Autocomplete<Map<String, dynamic>>(
                                optionsBuilder: (TextEditingValue textEditingValue) {
                                  if (textEditingValue.text.isEmpty) {
                                    return const Iterable<Map<String, dynamic>>.empty();
                                  }
                                  return _filteredProjects.where((project) {
                                    final projectId = project['projectId'].toString().toLowerCase();
                                    final title = project['title'].toString().toLowerCase();
                                    final searchQuery = textEditingValue.text.toLowerCase();
                                    return projectId.contains(searchQuery) || title.contains(searchQuery);
                                  });
                                },
                                displayStringForOption: (Map<String, dynamic> option) => 
                                    '${option['projectId']} - ${option['title']}',
                                onSelected: (Map<String, dynamic> selection) {
                                  _projectIdController.text = selection['projectId'];
                                  _handleProjectIdChange(selection['projectId']);
                                },
                                fieldViewBuilder: (
                                  BuildContext context,
                                  TextEditingController fieldController,
                                  FocusNode fieldFocusNode,
                                  VoidCallback onFieldSubmitted,
                                ) {
                                  return TextField(
                                    controller: fieldController,
                                    focusNode: fieldFocusNode,
                                    decoration: InputDecoration(
                                      hintText: 'Enter Project ID',
                                      prefixIcon: Icon(Icons.assignment),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      errorText: _projectId != null && _projectId!.isEmpty
                                          ? 'Please enter a Project ID'
                                          : null,
                                    ),
                                    onChanged: _handleProjectIdChange,
                                    textCapitalization: TextCapitalization.characters,
                                  );
                                },
                                optionsViewBuilder: (
                                  BuildContext context,
                                  AutocompleteOnSelected<Map<String, dynamic>> onSelected,
                                  Iterable<Map<String, dynamic>> options,
                                ) {
                                  return Align(
                                    alignment: Alignment.topLeft,
                                    child: Material(
                                      elevation: 4.0,
                                      child: Container(
                                        constraints: BoxConstraints(
                                          maxHeight: 200,
                                          maxWidth: MediaQuery.of(context).size.width - 72,
                                        ),
                                        child: ListView.builder(
                                          padding: EdgeInsets.zero,
                                          shrinkWrap: true,
                                          itemCount: options.length,
                                          itemBuilder: (BuildContext context, int index) {
                                            final option = options.elementAt(index);
                                            return ListTile(
                                              title: Text('${option['projectId']} - ${option['title']}'),
                                              onTap: () => onSelected(option),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              if (_projectId != null && _projectId!.isNotEmpty) ...[
                                SizedBox(height: 12),
                                Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Selected: $_projectId',
                                        style: TextStyle(
                                          color: Theme.of(context).primaryColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 20),

                      // Periods Selection Card
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Select Periods',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                              SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: List.generate(7, (index) {
                                  final period = index + 1;
                                  final isMarked = _markedPeriods.contains(period);
                                  final isSelected = _selectedPeriods.contains(period);
                                  final isDisabled = widget.isEditMode && !isMarked;

                                  return FilterChip(
                                    label: Text('Period $period'),
                                    selected: isSelected,
                                    onSelected: isDisabled
                                        ? null
                                        : (bool selected) {
                                            setState(() {
                                              if (selected) {
                                                _selectedPeriods.add(period);
                                              } else {
                                                _selectedPeriods.remove(period);
                                              }
                                            });
                                          },
                                    backgroundColor: isDisabled
                                        ? Colors.grey[200]
                                        : isMarked
                                            ? Colors.orange[50]
                                            : null,
                                    selectedColor: isMarked
                                        ? Colors.orange[200]
                                        : Theme.of(context).primaryColor,
                                    checkmarkColor: Colors.white,
                                    showCheckmark: true,
                                  );
                                }),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 30),

                      // Submit Button
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: _proceedToNextScreen,
                          icon: Icon(Icons.arrow_forward),
                          label: Text(
                            widget.isEditMode ? 'Edit Attendance' : 'Mark Attendance',
                            style: TextStyle(fontSize: 16),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
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