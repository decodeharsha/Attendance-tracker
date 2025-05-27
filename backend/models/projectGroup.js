const mongoose = require('mongoose');

const validateStudentId = function(v) {
  try {
    if (!v) {
      console.log('Validation failed: studentId is empty');
      return false;
    }
    const cleanId = String(v).toUpperCase().trim();
    const isValid = /^STU\d{3}$/.test(cleanId);
    console.log('Validating studentId in model:', {
      original: v,
      cleaned: cleanId,
      isValid: isValid
    });
    return isValid;
  } catch (error) {
    console.error('Error in studentId validation:', error);
    return false;
  }
};

const ProjectGroupSchema = new mongoose.Schema({
  formId: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'ProjectForm', 
    required: [true, 'Form ID is required']
  },
  projectIndex: { 
    type: Number, 
    required: [true, 'Project index is required']
  },
  projectId: { 
    type: String, 
    required: [true, 'Project ID is required']
  },
  teamLeader: { 
    type: String, 
    required: [true, 'Team leader ID is required'],
    validate: {
      validator: validateStudentId,
      message: props => `${props.value} is not a valid student ID! Must be in format STU001`
    }
  },
  teamMembers: [{ 
    type: String,
    validate: {
      validator: validateStudentId,
      message: props => `${props.value} is not a valid student ID! Must be in format STU001`
    }
  }],
  registeredAt: { type: Date, default: Date.now }
});

// Pre-save middleware to ensure IDs are in uppercase
ProjectGroupSchema.pre('save', function(next) {
  try {
    console.log('Pre-save middleware - Original data:', {
      teamLeader: this.teamLeader,
      teamMembers: this.teamMembers
    });

    if (this.teamLeader) {
      this.teamLeader = String(this.teamLeader).toUpperCase().trim();
    }
    if (this.teamMembers && this.teamMembers.length > 0) {
      this.teamMembers = this.teamMembers.map(id => String(id).toUpperCase().trim());
    }

    console.log('Pre-save middleware - Formatted data:', {
      teamLeader: this.teamLeader,
      teamMembers: this.teamMembers
    });

    next();
  } catch (error) {
    console.error('Error in pre-save middleware:', error);
    next(error);
  }
});

module.exports = mongoose.model('ProjectGroup', ProjectGroupSchema); 