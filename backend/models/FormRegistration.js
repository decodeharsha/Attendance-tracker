const mongoose = require('mongoose');

const formRegistrationSchema = new mongoose.Schema({
    formId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Form',
        required: [true, 'formId is required']
    },
    projectRegistrations: [{
        projectId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'Project',
            required: [true, 'projectId is required']
        },
        studentGroupIds: [{
            type: mongoose.Schema.Types.ObjectId,
            ref: 'StudentGroup',
            required: [true, 'studentGroupId is required']
        }]
    }],
    createdAt: {
        type: Date,
        default: Date.now
    },
    updatedAt: {
        type: Date,
        default: Date.now
    }
});

// Validate projectRegistrations array
formRegistrationSchema.pre('validate', function(next) {
    if (!this.projectRegistrations || !Array.isArray(this.projectRegistrations)) {
        next(new Error('projectRegistrations must be an array'));
    }
    next();
});

// Update the updatedAt timestamp before saving
formRegistrationSchema.pre('save', function(next) {
    this.updatedAt = Date.now();
    next();
});

const FormRegistration = mongoose.model('FormRegistration', formRegistrationSchema);

module.exports = FormRegistration; 