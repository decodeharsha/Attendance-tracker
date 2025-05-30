const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const connectDB = require('./config/db');
const authRoutes = require('./routes/auth');
const attendanceRoutes = require('./routes/attendance');
const projectRoutes = require('./routes/project');
const projectFormRoutes = require('./routes/projectForm');
const projectGroupRoutes = require('./routes/projectGroup');
const formRegistrationRoutes = require('./routes/formRegistrationRoutes');
const projectFormController = require('./controllers/projectFormController');

const app = express();

connectDB();

// Middleware
// Configure CORS to accept requests from any origin
app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));
app.use(express.json({ limit: '10mb' }));

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/attendance', attendanceRoutes);
app.use('/api/projects', projectRoutes);
app.use('/api/project-forms', projectFormRoutes);
app.use('/api/project-groups', projectGroupRoutes);
app.use('/api/form-registrations', formRegistrationRoutes);

// Schedule form status check every hour
setInterval(async () => {
  try {
    const deactivatedCount = await projectFormController.checkAndDeactivateForms();
    if (deactivatedCount > 0) {
      console.log(`Automatically deactivated ${deactivatedCount} forms`);
    }
  } catch (error) {
    console.error('Error in scheduled form check:', error);
  }
}, 60 * 60 * 1000); // Run every hour

// Start server
const PORT = process.env.PORT || 3000;
// Listen on all network interfaces (0.0.0.0) to allow external connections
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running on port ${PORT}`);
  console.log(`Server accessible at http://localhost:${PORT} and your local network IP`);
});