const express = require('express');
const router = express.Router();
const projectGroupController = require('../controllers/projectGroupController');
const auth = require('../middleware/auth');

// Initialize registration status for a form
router.post('/initialize-registration', auth, projectGroupController.initializeRegistration);

// Register a new project group
router.post('/register', auth, projectGroupController.registerGroup);

// Get all groups for a specific form
router.get('/form/:formId', auth, projectGroupController.getGroups);

// Get registration status for a form
router.get('/registration-status/:formId', auth, projectGroupController.getRegistrationStatus);

// Get students by form ID (admin only)
router.get('/students/:formId', auth, projectGroupController.getStudentsByFormId);

// Get students by form name (admin only)
router.get('/students/by-name/:formName', auth, projectGroupController.getStudentsByFormName);

module.exports = router;