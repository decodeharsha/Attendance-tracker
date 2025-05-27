class AttendanceRecord {
  final String date;
  final Map<String, String> periods;

  AttendanceRecord({required this.date, required this.periods});

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      date: json['date'],
      periods: Map<String, String>.from(json['periods']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'periods': periods,
    };
  }
}

class Attendance {
  final String studentId;
  final int sessionsHeld;
  final int sessionsPresent;
  final List<AttendanceRecord>? recentAttendance;

  Attendance({
    required this.studentId,
    required this.sessionsHeld,
    required this.sessionsPresent,
    this.recentAttendance,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      studentId: json['studentId'],
      sessionsHeld: json['sessionsHeld'],
      sessionsPresent: json['sessionsPresent'],
      recentAttendance: json['recentAttendance'] != null
          ? (json['recentAttendance'] as List)
              .map((record) => AttendanceRecord.fromJson(record))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'sessionsHeld': sessionsHeld,
      'sessionsPresent': sessionsPresent,
      'recentAttendance': recentAttendance?.map((record) => record.toJson()).toList(),
    };
  }
} 