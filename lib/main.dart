import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/login_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' as io;
import 'screens/student_dashboard.dart';
import 'screens/faculty_dashboard.dart';
import 'screens/admin_dashboard.dart';
import 'screens/edit_attendance_screen.dart';
import 'screens/download_attendance_screen.dart';
import 'screens/create_project_screen.dart';
import 'screens/projects_screen.dart';
import 'screens/project_form_screen.dart';
import 'screens/project_selection_screen.dart';
import 'screens/student_forms_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Request all necessary permissions at app startup
  if (io.Platform.isAndroid) {
    await requestPermissions();
  }
  
  runApp(MyApp());
}

Future<void> requestPermissions() async {
  // Request all storage permissions upfront
  await [    
    Permission.storage,
    Permission.manageExternalStorage,
  ].request();
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            theme: themeProvider.themeData,
            initialRoute: '/auth',
            routes: {
              '/auth': (context) => LoginScreen(),
              '/student': (context) => StudentDashboard(),
              '/student-forms': (context) => StudentFormsScreen(),
              '/faculty': (context) => FacultyDashboard(),
              '/admin': (context) => AdminDashboard(),
              '/edit-attendance': (context) {
                final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
                return EditAttendanceScreen(
                  projectId: args['projectId'] as String,
                  date: args['date'] as String,
                  periods: args['periods'] as List<int>,
                );
              },
              '/download-attendance': (context) => DownloadAttendanceScreen(),
              '/create-project': (context) => CreateProjectScreen(),
              '/projects': (context) => ProjectsScreen(),
              '/project-forms': (context) => ProjectFormScreen(),
              '/project-selection': (context) => ProjectSelectionScreen(),
            },
          );
        },
      ),
    );
  }
}