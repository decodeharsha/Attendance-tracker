const mongoose = require('mongoose');

const studentAttendanceSchema = new mongoose.Schema({
  studentId: {
    type: String,
    required: true,
    ref: 'Student'
  },
  date: {
    type: String,
    required: true
  },
  periods: {
    1: { type: String, enum: ['present', 'absent', 'not marked'], default: 'not marked' },
    2: { type: String, enum: ['present', 'absent', 'not marked'], default: 'not marked' },
    3: { type: String, enum: ['present', 'absent', 'not marked'], default: 'not marked' },
    4: { type: String, enum: ['present', 'absent', 'not marked'], default: 'not marked' },
    5: { type: String, enum: ['present', 'absent', 'not marked'], default: 'not marked' },
    6: { type: String, enum: ['present', 'absent', 'not marked'], default: 'not marked' },
    7: { type: String, enum: ['present', 'absent', 'not marked'], default: 'not marked' }
  }
});

// Create compound index for date and studentId
studentAttendanceSchema.index({ date: 1, studentId: 1 }, { unique: true });

module.exports = mongoose.model('StudentAttendance', studentAttendanceSchema); 