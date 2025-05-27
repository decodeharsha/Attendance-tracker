const mongoose = require('mongoose');

const ProjectGroupSchema = new mongoose.Schema({
  formId: { type: mongoose.Schema.Types.ObjectId, ref: 'ProjectForm', required: true },
  projectIndex: { type: Number, required: true }, // index of the project in the form's projects array
  projectId: { type: String, required: true }, // Store as string to match the project's projectId
  teamLeader: { type: String, required: true }, // Store student ID as string
  teamMembers: [{ type: String }], // Store student IDs as strings
  year: { type: Number, required: true },
  registeredAt: { type: Date, default: Date.now }
});

// Pre-save middleware to convert student IDs to uppercase
ProjectGroupSchema.pre('save', function(next) {
  this.teamLeader = this.teamLeader.toUpperCase();
  this.teamMembers = this.teamMembers.map(id => id.toUpperCase());
  next();
});

module.exports = mongoose.model('ProjectGroupRegistration', ProjectGroupSchema);