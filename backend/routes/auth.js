const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const auth = require('../middleware/auth');
const adminAuth = require('../middleware/adminAuth'); // assuming you have an adminAuth middleware

router.post('/login', authController.login);
router.get('/me', auth, authController.getCurrentUser);
router.post('/reset-password', auth, authController.resetPassword);
// Admin route to reset any user's password to 'password123'
router.post('/admin-reset-password', auth, adminAuth, authController.adminResetUserPassword);

module.exports = router;