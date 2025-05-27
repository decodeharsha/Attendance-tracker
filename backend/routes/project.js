const express = require('express');
const router = express.Router();
const projectController = require('../controllers/projectController');
const auth = require('../middleware/auth');

// Create a new project (admin or faculty only)
router.post('/', auth, (req, res, next) => {
  if (req.user.role !== 'admin' && req.user.role !== 'faculty') {
    return res.status(403).json({ message: 'Only admins and faculty can create projects' });
  }
  next();
}, projectController.createProject);

// Get all projects
router.get('/', auth, projectController.getProjects);

// Update a project (admin or faculty only)
router.put('/:projectId', auth, (req, res, next) => {
  if (req.user.role !== 'admin' && req.user.role !== 'faculty') {
    return res.status(403).json({ message: 'Only admins and faculty can update projects' });
  }
  next();
}, projectController.updateProject);

// Delete a project (admin or faculty only)
router.delete('/:projectId', auth, (req, res, next) => {
  if (req.user.role !== 'admin' && req.user.role !== 'faculty') {
    return res.status(403).json({ message: 'Only admins and faculty can delete projects' });
  }
  next();
}, projectController.softDeleteProject);

module.exports = router; 