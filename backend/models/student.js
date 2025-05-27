const mongoose = require('mongoose');

const studentSchema = new mongoose.Schema({
  name: String,  studentId: { 
    type: String, 
    unique: true,
    required: true
  },
  year: { 
    type: String, 
    required: true,
    enum: ['1', '2', '3', '4']
  },
  department: String,
  role: { 
    type: String, 
    enum: ['student', 'team_leader'],
    default: 'student'
  },
  password: String,
  projectId: { type: String }
});

// Add pre-save middleware to ensure studentId is properly formatted
studentSchema.pre('save', function(next) {
  if (this.studentId) {
    this.studentId = String(this.studentId).toUpperCase().trim();
  }
  next();
});

module.exports = mongoose.model('Student', studentSchema);