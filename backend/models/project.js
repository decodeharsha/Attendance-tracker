const mongoose = require('mongoose');

const ProjectSchema = new mongoose.Schema({
  projectId: { type: String, required: true, unique: true },
  title: { type: String, required: true },
  description: String,
  maxGroups: { type: Number, required: true },
  minMembers: { type: Number, required: true },
  maxMembers: { type: Number, required: true },
  createdAt: { type: Date, default: Date.now },
  isDeleted: { type: Boolean, default: false }
});

module.exports = mongoose.model('Project', ProjectSchema); 