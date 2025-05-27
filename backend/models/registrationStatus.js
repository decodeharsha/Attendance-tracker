const mongoose = require('mongoose');

const RegistrationStatusSchema = new mongoose.Schema({
  formId: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'ProjectForm', 
    required: true 
  },
  year: { 
    type: Number, 
    required: true 
  },
  registered: [{
    studentId: String,
    projectId: String,
    registrationDate: {
      type: Date,
      default: Date.now
    }
  }],
  unregistered: [{
    studentId: String,
    addedDate: {
      type: Date,
      default: Date.now
    }
  }],
  createdAt: { 
    type: Date, 
    default: Date.now 
  }
});

// Create compound index for formId and year
RegistrationStatusSchema.index({ formId: 1, year: 1 }, { unique: true });

module.exports = mongoose.model('RegistrationStatus', RegistrationStatusSchema);
