const FormRegistration = require('../models/FormRegistration');
const ProjectForm = require('../models/projectForm');
const ProjectGroupRegistration = require('../models/projectGroupRegistration');
const Project = require('../models/project');

// Create a new form registration
exports.createFormRegistration = async (req, res) => {
    try {
        console.log('Received form registration request:', req.body);
        const { formId, projectRegistrations } = req.body;
        
        if (!formId) {
            console.log('Error: formId is missing');
            return res.status(400).json({ message: 'formId is required' });
        }

        if (!projectRegistrations || !Array.isArray(projectRegistrations)) {
            console.log('Error: projectRegistrations must be an array');
            return res.status(400).json({ message: 'projectRegistrations must be an array' });
        }

        const formRegistration = new FormRegistration({
            formId,
            projectRegistrations
        });

        console.log('Attempting to save form registration:', formRegistration);
        const savedRegistration = await formRegistration.save();
        console.log('Successfully saved form registration:', savedRegistration);
        
        res.status(201).json(savedRegistration);
    } catch (error) {
        console.error('Error saving form registration:', error);
        res.status(400).json({ 
            message: error.message,
            details: error.stack
        });
    }
};

// Create initial form registration when form is created
exports.createInitialFormRegistration = async (formId) => {
    try {
        console.log('Creating initial form registration for form:', formId);
        
        // Get the form to access its projects
        const form = await ProjectForm.findById(formId);
        if (!form) {
            throw new Error('Form not found');
        }

        // Create project registrations array with all projects from the form
        const projectRegistrations = form.projects.map(project => ({
            projectId: project.projectId,
            studentGroupIds: [] // Empty array initially for each project
        }));

        const formRegistration = new FormRegistration({
            formId,
            projectRegistrations
        });

        const savedRegistration = await formRegistration.save();
        console.log('Initial form registration created with projects:', savedRegistration);
        return savedRegistration;
    } catch (error) {
        console.error('Error creating initial form registration:', error);
        throw error;
    }
};

// Register students for a project
exports.registerStudentsForProject = async (formId, projectId, studentGroupIds) => {
    try {
        console.log('Registering students for project:', { formId, projectId, studentGroupIds });
        
        // Find the form registration
        const formRegistration = await FormRegistration.findOne({ formId });
        if (!formRegistration) {
            throw new Error('Form registration not found');
        }

        // Find the project registration
        const projectRegistration = formRegistration.projectRegistrations.find(
            pr => pr.projectId.toString() === projectId.toString()
        );

        if (!projectRegistration) {
            throw new Error('Project not found in form registration');
        }

        // Add the new student group IDs to the existing ones
        projectRegistration.studentGroupIds = [
            ...new Set([...projectRegistration.studentGroupIds, ...studentGroupIds])
        ];

        const updatedRegistration = await formRegistration.save();
        console.log('Updated form registration:', updatedRegistration);
        return updatedRegistration;
    } catch (error) {
        console.error('Error registering students for project:', error);
        throw error;
    }
};

// Get form registration by form ID
exports.getFormRegistrationByFormId = async (req, res) => {
    try {
        const { formId } = req.params;
        const registration = await FormRegistration.findOne({ formId })
            .populate('formId')
            .populate('projectRegistrations.projectId')
            .populate('projectRegistrations.studentGroupIds');
        
        if (!registration) {
            return res.status(404).json({ message: 'Form registration not found' });
        }
        res.json(registration);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// Get all form registrations
exports.getAllFormRegistrations = async (req, res) => {
    try {
        const registrations = await FormRegistration.find()
            .populate('formId')
            .populate('projectRegistrations.projectId')
            .populate('projectRegistrations.studentGroupIds');
        res.json(registrations);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// Get form registration by ID
exports.getFormRegistrationById = async (req, res) => {
    try {
        const registration = await FormRegistration.findById(req.params.id)
            .populate('formId')
            .populate('projectRegistrations.projectId')
            .populate('projectRegistrations.studentGroupIds');
        
        if (!registration) {
            return res.status(404).json({ message: 'Form registration not found' });
        }
        res.json(registration);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// Update form registration
exports.updateFormRegistration = async (req, res) => {
    try {
        const { formId, projectRegistrations } = req.body;
        
        const updatedRegistration = await FormRegistration.findOneAndUpdate(
            { formId },
            {
                projectRegistrations,
                updatedAt: Date.now()
            },
            { new: true }
        ).populate('formId')
         .populate('projectRegistrations.projectId')
         .populate('projectRegistrations.studentGroupIds');

        if (!updatedRegistration) {
            return res.status(404).json({ message: 'Form registration not found' });
        }
        res.json(updatedRegistration);
    } catch (error) {
        res.status(400).json({ message: error.message });
    }
};

// Delete form registration
exports.deleteFormRegistration = async (req, res) => {
    try {
        const { formId } = req.params;
        const deletedRegistration = await FormRegistration.findOneAndDelete({ formId });
        
        if (!deletedRegistration) {
            return res.status(404).json({ message: 'Form registration not found' });
        }
        res.json({ message: 'Form registration deleted successfully' });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// Download project registration information
exports.downloadProjectRegistrations = async (req, res) => {
    try {
        const { formName } = req.params;
        console.log('Downloading registrations for form:', formName);

        // Get the form with its projects
        const form = await ProjectForm.findOne({ formName });
        if (!form) {
            return res.status(404).json({ message: 'Form not found' });
        }
        console.log('Found form:', {
            formName: form.formName,
            formId: form._id,
            projects: form.projects
        });

        // Get all project group registrations for this form
        const groupRegistrations = await ProjectGroupRegistration.find({ formId: form._id });
        console.log('Found registrations:', JSON.stringify(groupRegistrations, null, 2));

        if (!groupRegistrations || groupRegistrations.length === 0) {
            return res.status(404).json({ message: 'No registrations found for this form' });
        }

        // Create CSV content with headers
        let csvContent = 'Project ID,Project Title,Team Leader ID,Team Member IDs,Registration Date\n';

        // Process each group registration
        for (const group of groupRegistrations) {
            console.log('Processing group:', {
                projectIndex: group.projectIndex,
                teamLeader: group.teamLeader,
                teamMembers: group.teamMembers
            });
            
            // Get project details from form's projects array using projectIndex
            const formProject = form.projects[group.projectIndex];
            if (!formProject) {
                console.log(`Project not found for index: ${group.projectIndex}`);
                continue;
            }

            console.log('Found project in form:', {
                projectId: formProject.projectId,
                title: formProject.title
            });

            // Format team member information
            const memberIds = Array.isArray(group.teamMembers) ? group.teamMembers.join('; ') : '';

            // Format registration date
            const registrationDate = new Date(group.registeredAt).toLocaleString();

            // Add row to CSV using project details from form
            const row = `${formProject.projectId},${formProject.title},${group.teamLeader},${memberIds},${registrationDate}\n`;
            console.log('Adding row to CSV:', row);
            csvContent += row;
        }

        console.log('Final CSV content:', csvContent);

        // Convert CSV content to Buffer
        const csvBuffer = Buffer.from(csvContent, 'utf-8');

        // Set response headers for file download
        res.setHeader('Content-Type', 'text/csv');
        res.setHeader('Content-Disposition', `attachment; filename=${formName}_registrations.csv`);
        res.setHeader('Content-Length', csvBuffer.length);

        // Send the CSV file as buffer
        res.send(csvBuffer);
    } catch (error) {
        console.error('Error downloading project registrations:', error);
        res.status(500).json({ message: error.message });
    }
}; 