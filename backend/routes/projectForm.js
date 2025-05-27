const express = require('express');
const router = express.Router();
const projectFormController = require('../controllers/projectFormController');
const auth = require('../middleware/auth');

// Create a new project form (admin only)
router.post('/', auth, projectFormController.createForm);

// Get project forms (filtered by year if specified)
router.get('/', auth, projectFormController.getForms);

// Toggle form status (admin only)
router.patch('/:formId/toggle', auth, projectFormController.toggleFormStatus);

// Delete form (admin only)
router.delete('/:formId', auth, projectFormController.deleteForm);

// Soft delete project (admin only)
router.delete('/:formId/projects/:projectId', auth, projectFormController.softDeleteProject);

module.exports = router; 