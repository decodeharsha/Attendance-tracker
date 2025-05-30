require('dotenv').config();
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const Student = require('../models/student');
const Faculty = require('../models/faculty');
const Admin = require('../models/admin');

exports.login = async (req, res) => {
  let { id, password, role } = req.body;
  let user;

  // Convert id to uppercase and trim whitespace
  if (typeof id === 'string') {
    id = id.toUpperCase().trim();
  }

  try {
    if (role === 'student') {
      user = await Student.findOne({ studentId: id });
    } else if (role === 'faculty') {
      user = await Faculty.findOne({ facultyId: id });
    } else if (role === 'admin') {
      user = await Admin.findOne({ adminId: id });
    }

    if (!user || !(await bcrypt.compare(password, user.password))) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    const token = jwt.sign({ id: user[role + 'Id'] || user.adminId, role }, process.env.JWT_SECRET, { expiresIn: '1h' });
    res.json({
      token,
      user: {
        id: user[role + 'Id'] || user.adminId,
        role,
        name: user.name,
        year: user.year,
        projectId: user.projectId,
        department: user.department,
        facultyId: user.facultyId,
      },
    });
  } catch (error) {
    res.status(500).json({ message: 'Server error' });
  }
};

exports.getCurrentUser = async (req, res) => {
  try {
    console.log('getCurrentUser - Request user:', req.user);
    const { role, id } = req.user;
    let user;

    console.log('getCurrentUser - Looking up user with role:', role, 'and id:', id);

    if (role === 'student') {
      user = await Student.findOne({ studentId: id });
    } else if (role === 'faculty') {
      user = await Faculty.findOne({ facultyId: id });
    } else if (role === 'admin') {
      user = await Admin.findOne({ adminId: id });
    }

    if (!user) {
      console.log('getCurrentUser - User not found for role:', role, 'and id:', id);
      return res.status(404).json({ 
        success: false,
        message: 'User not found' 
      });
    }

    console.log('getCurrentUser - Found user:', user);

    const responseData = {
      success: true,
      user: {
        id: user[role + 'Id'] || user.adminId,
        role,
        name: user.name,
        year: user.year,
        projectId: user.projectId,
        department: user.department,
        facultyId: user.facultyId,
      }
    };

    console.log('getCurrentUser - Sending response:', responseData);
    res.json(responseData);
  } catch (error) {
    console.error('getCurrentUser error:', error);
    res.status(500).json({ 
      success: false,
      message: 'Server error while fetching user details' 
    });
  }
};

// Admin: Reset any user's password to 'password123'
exports.adminResetUserPassword = async (req, res) => {
  const { userId, userType } = req.body;
  if (!req.user || req.user.role !== 'admin') {
    return res.status(403).json({ message: 'Only admin can reset user passwords.' });
  }
  if (!userId || !userType) {
    return res.status(400).json({ message: 'userId and userType are required.' });
  }
  let user, Model, query;
  if (userType === 'student') {
    Model = Student;
    query = { studentId: userId.toUpperCase().trim() };
  } else if (userType === 'faculty') {
    Model = Faculty;
    query = { facultyId: userId.toUpperCase().trim() };
  } else if (userType === 'admin') {
    Model = Admin;
    query = { adminId: userId.toUpperCase().trim() };
  } else {
    return res.status(400).json({ message: 'Invalid userType.' });
  }
  try {
    user = await Model.findOne(query);
    if (!user) {
      return res.status(404).json({ message: 'User not found.' });
    }
    const hashedPassword = await bcrypt.hash('password123', 10);
    user.password = hashedPassword;
    await user.save();
    res.status(200).json({ message: 'Password reset to password123 successfully.' });
  } catch (error) {
    console.error('Admin reset password error:', error);
    res.status(500).json({ message: 'Server error during admin password reset.' });
  }
};

exports.resetPassword = async (req, res) => {
  const { currentPassword, newPassword } = req.body;
  const { id, role } = req.user;

  try {
    let user;
    if (role === 'student') {
      user = await Student.findOne({ studentId: id });
    } else if (role === 'faculty') {
      user = await Faculty.findOne({ facultyId: id });
    } else if (role === 'admin') {
      user = await Admin.findOne({ adminId: id });
    }

    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    // Verify current password
    const isPasswordValid = await bcrypt.compare(currentPassword, user.password);
    if (!isPasswordValid) {
      return res.status(401).json({ message: 'Current password is incorrect' });
    }

    // Hash and update new password
    const hashedPassword = await bcrypt.hash(newPassword, 10);
    user.password = hashedPassword;
    await user.save();

    res.status(200).json({ message: 'Password reset successfully' });
  } catch (error) {
    console.error('Reset password error:', error);
    res.status(500).json({ message: 'Server error during password reset' });
  }
};