const mongoose = require('mongoose');
const connectDB = require('../config/db');
const ProjectForm = require('../models/projectForm');

async function checkForms() {
  try {
    await connectDB();
    console.log('MongoDB connected');

    const forms = await ProjectForm.find({})
      .populate('releasedBy', 'name')
      .sort({ createdAt: -1 });

    console.log('\nFound forms:', forms.length);
    forms.forEach((form, index) => {
      console.log(`\nForm ${index + 1}:`);
      console.log('ID:', form._id);
      console.log('Year:', form.year);
      console.log('Is Active:', form.isActive);
      console.log('Released By:', form.releasedBy?.name);
      console.log('Projects:', form.projects.length);
      form.projects.forEach((project, pIndex) => {
        console.log(`  Project ${pIndex + 1}:`);
        console.log('    ID:', project.projectId);
        console.log('    Title:', project.title);
      });
    });

    process.exit(0);
  } catch (error) {
    console.error('Error:', error);
    process.exit(1);
  }
}

checkForms(); 