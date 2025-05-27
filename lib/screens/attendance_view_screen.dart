import 'package:flutter/material.dart';
import '../models/attendance.dart';

class AttendanceViewScreen extends StatefulWidget {
  final Attendance attendance;
  final String studentName;

  const AttendanceViewScreen({required this.attendance, required this.studentName});

  @override
  _AttendanceViewScreenState createState() => _AttendanceViewScreenState();
}

class _AttendanceViewScreenState extends State<AttendanceViewScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getAttendanceColor(double percentage) {
    if (widget.attendance.sessionsHeld == 0) return Colors.grey;
    if (percentage < 65) return Colors.red;
    if (percentage < 75) return Colors.orange;
    return Colors.green;
  }

  Color _getPeriodColor(String status) {
    switch (status) {
      case 'present':
        return Colors.green;
      case 'absent':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final percentage = widget.attendance.sessionsHeld == 0
        ? 0.0
        : (widget.attendance.sessionsPresent / widget.attendance.sessionsHeld * 100);
    final percentageText = percentage.toStringAsFixed(1);
    final attendanceColor = _getAttendanceColor(percentage);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Attendance Details',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      attendanceColor.withOpacity(0.8),
                      attendanceColor.withOpacity(0.4),
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        child: Icon(
                          Icons.person,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        widget.studentName,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatCard(
                                icon: Icons.check_circle,
                                label: 'Present',
                                value: widget.attendance.sessionsPresent.toString(),
                                color: Colors.green,
                              ),
                              _buildStatCard(
                                icon: Icons.cancel,
                                label: 'Absent',
                                value: (widget.attendance.sessionsHeld - widget.attendance.sessionsPresent).toString(),
                                color: Colors.red,
                              ),
                              _buildStatCard(
                                icon: Icons.calendar_today,
                                label: 'Total',
                                value: widget.attendance.sessionsHeld.toString(),
                                color: Colors.blue,
                              ),
                            ],
                          ),
                          SizedBox(height: 24),
                          AnimatedBuilder(
                            animation: _animation,
                            builder: (context, child) {
                              return SemiRingWidget(
                                percentage: percentage * _animation.value,
                                color: attendanceColor,
                                percentageText: percentageText,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Recent Attendance',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  if (widget.attendance.recentAttendance != null && widget.attendance.recentAttendance!.isNotEmpty)
                    ...widget.attendance.recentAttendance!.map((record) {
                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    color: Colors.blue,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Date: ${record.date}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: record.periods.entries.map((entry) {
                                  final isPresent = entry.value.toLowerCase() == 'present';
                                  return Container(
                                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: _getPeriodColor(entry.value).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: _getPeriodColor(entry.value)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isPresent ? Icons.check_circle : Icons.cancel,
                                          color: _getPeriodColor(entry.value),
                                          size: 16,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'P${entry.key}',
                                          style: TextStyle(
                                            color: _getPeriodColor(entry.value),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList()
                  else
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Center(
                          child: Text(
                            'No recent attendance records',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

class SemiRingWidget extends StatelessWidget {
  final double percentage;
  final Color color;
  final String percentageText;

  const SemiRingWidget({
    required this.percentage,
    required this.color,
    required this.percentageText,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        CustomPaint(
          size: Size(200, 100), // Larger size for better visibility
          painter: SemiRingPainter(
            percentage: percentage,
            color: color,
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$percentageText%',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              'Attendance',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class SemiRingPainter extends CustomPainter {
  final double percentage;
  final Color color;

  SemiRingPainter({required this.percentage, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    // Background ring
    final bgPaint = Paint()
      ..color = Colors.grey[200]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;
    canvas.drawArc(
      Rect.fromLTWH(0, 0, size.width, size.width),
      180 * (3.14159 / 180),
      180 * (3.14159 / 180),
      false,
      bgPaint,
    );

    // Foreground animated ring
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    final sweepAngle = (percentage / 100) * 180;
    canvas.drawArc(
      Rect.fromLTWH(0, 0, size.width, size.width),
      180 * (3.14159 / 180),
      (sweepAngle * (3.14159 / 180)),
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}