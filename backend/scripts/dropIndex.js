const mongoose = require('mongoose');
const connectDB = require('../config/db');

async function dropIndex() {
  try {
    await connectDB();
    const db = mongoose.connection.db;
    
    // Drop the index
    await db.collection('projectforms').dropIndex('projects.projectId_1');
    console.log('Successfully dropped the unique index on projects.projectId');
    
    process.exit(0);
  } catch (error) {
    console.error('Error dropping index:', error);
    process.exit(1);
  }
}

dropIndex(); 