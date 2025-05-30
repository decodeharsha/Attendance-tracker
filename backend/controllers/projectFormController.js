const ProjectForm = require('../models/projectForm');
const Student = require('../models/student');
const RegistrationStatus = require('../models/registrationStatus');
const formRegistrationController = require('./formRegistrationController');

exports.createForm = async (req, res) => {
  try {
    const { year, formName, projects, startDate, endDate } = req.body;
    const releasedBy = req.user._id; // From auth middleware

    console.log('Creating form with data:', {
      year,
      formName,
      projects,
      startDate,
      endDate,
      releasedBy
    });

    // Get all students of the specified year
    const students = await Student.find({ year: year.toString() });
    const studentIds = students.map(student => student.studentId);

    const form = new ProjectForm({
      year,
      formName,
      releasedBy,
      projects,
      startDate: new Date(startDate),
      endDate: new Date(endDate),
      isActive: true,
      registeredStudents: [],
      unregisteredStudents: studentIds
    });

    await form.save();

    // Initialize registration status
    const registrationStatus = new RegistrationStatus({
      formId: form._id,
      year,
      unregistered: studentIds.map(studentId => ({
        studentId,
        addedDate: new Date()
      })),
      registered: []
    });

    await registrationStatus.save();

    // Create initial form registration
    try {
      await formRegistrationController.createInitialFormRegistration(form._id);
    } catch (error) {
      console.error('Error creating initial form registration:', error);
      // Don't fail the form creation if registration creation fails
    }

    res.status(201).json(form);
  } catch (error) {
    console.error('Error creating project form:', error);
    if (error.name === 'ValidationError') {
      return res.status(400).json({
        message: 'Validation error',
        details: Object.values(error.errors).map(err => err.message)
      });
    }
    res.status(500).json({ message: 'Server error' });
  }
};

exports.getForms = async (req, res) => {
  try {
    const { year } = req.query;
    const query = { ...(year ? { year: parseInt(year) } : {}) };
    
    console.log('User info:', {
      role: req.user.role,
      year: req.user.year,
      id: req.user._id
    });
    
    // If user is a student, only show active forms for their year
    if (req.user.role === 'student') {
      if (!req.user.year) {
        console.log('Student year not found in user info');
        return res.status(400).json({
          success: false,
          message: 'Student year information not found'
        });
      }
      query.isActive = true;
      query.year = req.user.year;
      console.log('Student viewing forms for year:', req.user.year);
    }
    // If admin or faculty, do not filter by year or isActive (see all forms)
    // No additional filtering needed for admin/faculty

    
    console.log('Query:', query);
    console.log('User role:', req.user.role);
    
    const forms = await ProjectForm.find(query)
      .populate('releasedBy', 'name')
      .sort({ createdAt: -1 });
    
    console.log('Found forms:', forms.length);
    forms.forEach(form => {
      console.log('Form details:', {
        id: form._id,
        year: form.year,
        isActive: form.isActive,
        releasedBy: form.releasedBy?.name,
        projects: form.projects.length
      });
    });
    
    // Format the response
    const formattedForms = forms.map(form => ({
      _id: form._id,
      year: form.year,
      formName: form.formName,
      isActive: form.isActive,
      releasedBy: {
        _id: form.releasedBy?._id,
        name: form.releasedBy?.name || 'Unknown'
      },
      projects: form.projects
        .filter(project => !project.isDeleted) // Only include non-deleted projects
        .map(project => ({
          projectId: project.projectId,
          title: project.title,
          description: project.description,
          maxGroups: project.maxGroups,
          minMembers: project.minMembers,
          maxMembers: project.maxMembers,
          registeredGroups: project.registeredGroups ?? 0
        })),
      createdAt: form.createdAt
    }));
    
    res.json({
      success: true,
      data: formattedForms
    });
  } catch (error) {
    console.error('Error fetching project forms:', error);
    res.status(500).json({ 
      success: false,
      message: 'Server error',
      error: error.message 
    });
  }
};

exports.toggleFormStatus = async (req, res) => {
  try {
    const { formId } = req.params;
    console.log('Toggling status for form:', formId);

    const form = await ProjectForm.findById(formId);
    if (!form) {
      return res.status(404).json({ 
        success: false,
        message: 'Form not found' 
      });
    }

    // Toggle the form status
    form.isActive = !form.isActive;
    await form.save();

    console.log('Form status updated:', {
      formId: form._id,
      isActive: form.isActive
    });
    
    res.json({
      success: true,
      message: form.isActive ? 'Form released successfully' : 'Form deactivated successfully',
      data: {
        _id: form._id,
        year: form.year,
        isActive: form.isActive,
        releasedBy: form.releasedBy
      }
    });
  } catch (error) {
    console.error('Error toggling form status:', error);
    res.status(500).json({ 
      success: false,
      message: 'Server error',
      error: error.message 
    });
  }
};

exports.deleteForm = async (req, res) => {
  try {
    const { formId } = req.params;
    console.log('Deleting form:', formId);

    // Check if user is admin
    if (req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Only admins can delete forms'
      });
    }

    const form = await ProjectForm.findById(formId);
    if (!form) {
      return res.status(404).json({
        success: false,
        message: 'Form not found'
      });
    }

    // Delete the form
    await ProjectForm.findByIdAndDelete(formId);

    // Also delete associated registration status
    await RegistrationStatus.findOneAndDelete({ formId });

    res.json({
      success: true,
      message: 'Form deleted successfully'
    });
  } catch (error) {
    console.error('Error deleting form:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message
    });
  }
};

exports.softDeleteProject = async (req, res) => {
  try {
    const { formId, projectId } = req.params;
    console.log('Soft deleting project:', { formId, projectId });

    // Check if user is admin
    if (req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Only admins can delete projects'
      });
    }

    const form = await ProjectForm.findById(formId);
    if (!form) {
      return res.status(404).json({
        success: false,
        message: 'Form not found'
      });
    }

    // Find the project and mark it as deleted
    const projectIndex = form.projects.findIndex(p => p.projectId === projectId);
    if (projectIndex === -1) {
      return res.status(404).json({
        success: false,
        message: 'Project not found in form'
      });
    }

    // Mark the project as deleted
    form.projects[projectIndex].isDeleted = true;
    await form.save();

    res.json({
      success: true,
      message: 'Project deleted successfully'
    });
  } catch (error) {
    console.error('Error soft deleting project:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message
    });
  }
};

exports.checkAndDeactivateForms = async () => {
  try {
    const now = new Date();
    const forms = await ProjectForm.find({
      isActive: true,
      endDate: { $lt: now }
    });

    for (const form of forms) {
      form.isActive = false;
      await form.save();
      console.log(`Form ${form.formName} (${form._id}) automatically deactivated`);
    }

    return forms.length;
  } catch (error) {
    console.error('Error in checkAndDeactivateForms:', error);
    throw error;
  }
}; 