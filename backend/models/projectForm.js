const mongoose = require('mongoose');

const ProjectSchema = new mongoose.Schema({
  projectId: { type: String, required: true },
  title: { type: String, required: true },
  description: String,
  maxGroups: { type: Number, required: true },
  minMembers: { type: Number, required: true },
  maxMembers: { type: Number, required: true },
  registeredGroups: { type: Number, default: 0 },
  isDeleted: { type: Boolean, default: false }
});

const ProjectFormSchema = new mongoose.Schema({
  year: { type: Number, required: true },
  formName: { type: String, required: true },
  releasedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'Admin' },
  projects: [ProjectSchema],
  isActive: { type: Boolean, default: true },
  createdAt: { type: Date, default: Date.now },
  registeredStudents: [{ type: String }],  // Array of student IDs who are registered
  unregisteredStudents: [{ type: String }] // Array of student IDs who are not yet registered
});

// Add validation to ensure projects array is not empty
ProjectFormSchema.pre('save', function(next) {
  if (this.projects.length === 0) {
    next(new Error('At least one project is required'));
  }
  next();
});

module.exports = mongoose.model('ProjectForm', ProjectFormSchema);