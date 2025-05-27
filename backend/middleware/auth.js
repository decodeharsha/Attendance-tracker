const jwt = require('jsonwebtoken');
const Student = require('../models/student');
const Admin = require('../models/admin');
const Faculty = require('../models/faculty');

module.exports = async (req, res, next) => {
  try {
    console.log('Auth middleware - Request headers:', req.headers);
    const token = req.headers.authorization?.split(' ')[1];
    if (!token) {
      console.log('Auth middleware - No token provided');
      return res.status(401).json({ message: 'No token provided' });
    }

    console.log('Auth middleware - Verifying token:', token);
    const decoded = jwt.verify(token, 'secret');
    console.log('Auth middleware - Decoded token:', decoded);
    
    // Check if user is a student
    if (decoded.role === 'student') {
      console.log('Auth middleware - Looking up student with ID:', decoded.id);
      const student = await Student.findOne({ studentId: decoded.id });
      if (!student) {
        console.log('Auth middleware - Student not found for ID:', decoded.id);
        return res.status(401).json({ message: 'Student not found' });
      }
      req.user = {
        _id: student._id,
        id: student.studentId,
        role: 'student',
        year: student.year
      };
      console.log('Auth middleware - Student authenticated:', req.user);
    }
    // Check if user is an admin
    else if (decoded.role === 'admin') {
      console.log('Auth middleware - Looking up admin with ID:', decoded.id);
      const admin = await Admin.findOne({ adminId: decoded.id });
      if (!admin) {
        console.log('Auth middleware - Admin not found for ID:', decoded.id);
        return res.status(401).json({ message: 'Admin not found' });
      }
      req.user = {
        _id: admin._id,
        id: admin.adminId,
        role: 'admin'
      };
      console.log('Auth middleware - Admin authenticated:', req.user);
    }
    // Check if user is faculty
    else if (decoded.role === 'faculty') {
      console.log('Auth middleware - Looking up faculty with ID:', decoded.id);
      const faculty = await Faculty.findOne({ facultyId: decoded.id });
      if (!faculty) {
        console.log('Auth middleware - Faculty not found for ID:', decoded.id);
        return res.status(401).json({ message: 'Faculty not found' });
      }
      req.user = {
        _id: faculty._id,
        id: faculty.facultyId,
        role: 'faculty'
      };
      console.log('Auth middleware - Faculty authenticated:', req.user);
    }
    else {
      console.log('Auth middleware - Invalid role:', decoded.role);
      return res.status(401).json({ message: 'Invalid user role' });
    }

    next();
  } catch (error) {
    console.error('Auth middleware error:', error);
    if (error.name === 'JsonWebTokenError') {
      console.log('Auth middleware - Invalid token error');
      return res.status(401).json({ message: 'Invalid token' });
    }
    if (error.name === 'TokenExpiredError') {
      console.log('Auth middleware - Token expired error');
      return res.status(401).json({ message: 'Token expired' });
    }
    console.log('Auth middleware - General authentication error');
    res.status(401).json({ message: 'Authentication failed' });
  }
};