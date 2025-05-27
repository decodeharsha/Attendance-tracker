const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const auth = require('../middleware/auth');

router.post('/login', authController.login);
router.get('/me', auth, authController.getCurrentUser);
router.post('/reset-password', auth, authController.resetPassword);

module.exports = router;