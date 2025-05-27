const express = require('express');
const router = express.Router();
const formRegistrationController = require('../controllers/formRegistrationController');
const auth = require('../middleware/auth');

// Create a new form registration
router.post('/', formRegistrationController.createFormRegistration);

// Get form registration by form ID
router.get('/form/:formId', formRegistrationController.getFormRegistrationByFormId);

// Get all form registrations
router.get('/', formRegistrationController.getAllFormRegistrations);

// Download project registrations (admin only)
router.get('/download/:formName', auth, formRegistrationController.downloadProjectRegistrations);

// Update form registration
router.put('/:formId', formRegistrationController.updateFormRegistration);

// Delete form registration
router.delete('/:formId', formRegistrationController.deleteFormRegistration);

module.exports = router; 