const mongoose = require('mongoose');
const ProjectGroupRegistration = require('../models/projectGroupRegistration');
const ProjectForm = require('../models/projectForm');
const Student = require('../models/student');
const RegistrationStatus = require('../models/registrationStatus');
const formRegistrationController = require('./formRegistrationController');

exports.registerGroup = async (req, res) => {
  const session = await mongoose.startSession();
  session.startTransaction();

  try {
    const { formId, projectIndex, teamLeader, teamMembers, projectId } = req.body;
    console.log('Registration request received:', { formId, projectIndex, teamLeader, teamMembers });
    
    const allStudentIds = [teamLeader, ...teamMembers];
    console.log('All student IDs:', allStudentIds);

    // 1. Get the form and verify it exists and is active
    const form = await ProjectForm.findById(formId).session(session);
    console.log('Form found:', form ? 'Yes' : 'No');
    
    if (!form || !form.isActive) {
      await session.abortTransaction();
      return res.status(400).json({
        success: false,
        message: 'Project form not found or is inactive'
      });
    }

    // 2. Get registration status
    const registrationStatus = await RegistrationStatus.findOne({ formId }).session(session);
    console.log('Registration status found:', registrationStatus ? 'Yes' : 'No');
    
    if (!registrationStatus) {
      await session.abortTransaction();
      return res.status(400).json({
        success: false,
        message: 'Registration status not found for this form'
      });
    }

    // 3. Check if all students are in unregistered list
    const unregisteredStudentIds = registrationStatus.unregistered.map(s => s.studentId);
    console.log('Unregistered students:', unregisteredStudentIds);
    
    const notUnregistered = allStudentIds.filter(id => !unregisteredStudentIds.includes(id));
    if (notUnregistered.length > 0) {
      await session.abortTransaction();
      return res.status(400).json({
        success: false,
        message: 'Registration failed',
        error: {
          type: 'UNREGISTERED_STUDENTS',
          details: {
            notUnregistered: notUnregistered,
            unregisteredList: unregisteredStudentIds,
            attemptedRegistration: allStudentIds
          },
          message: `The following students are not eligible for registration: ${notUnregistered.join(', ')}. They are either already registered or not in the unregistered list.`
        }
      });
    }

    // 4. Verify project exists and has available slots
    const project = form.projects[projectIndex];
    console.log('Project found:', project ? 'Yes' : 'No');
    
    if (!project) {
      await session.abortTransaction();
      return res.status(400).json({
        success: false,
        message: 'Invalid project index'
      });
    }

    if (project.registeredGroups >= project.maxGroups) {
      await session.abortTransaction();
      return res.status(400).json({
        success: false,
        message: 'No slots available for this project'
      });
    }

    // 5. Verify team size
    const teamSize = teamMembers.length + 1; // Including leader
    if (teamSize < project.minMembers || teamSize > project.maxMembers) {
      await session.abortTransaction();
      return res.status(400).json({
        success: false,
        message: `Team size must be between ${project.minMembers} and ${project.maxMembers}`
      });
    }

    // 6. Verify all students exist in the database
    const students = await Student.find({ studentId: { $in: allStudentIds } }).session(session);
    if (students.length !== allStudentIds.length) {
      await session.abortTransaction();
      return res.status(400).json({
        success: false,
        message: 'One or more students not found in the database'
      });
    }

    // Create the registration
    const registration = new ProjectGroupRegistration({
      formId,
      projectIndex,
      teamLeader,
      teamMembers,
      year: form.year,
      projectId: projectId,
      formName: form.name
    });
    await registration.save({ session });
    console.log('Registration saved successfully');

    // Update form registration with the new student group
    try {
      await formRegistrationController.registerStudentsForProject(
        formId,
        projectId,
        [registration._id] // Pass the registration ID as the student group ID
      );
      console.log('Form registration updated successfully');
    } catch (error) {
      console.error('Error updating form registration:', error);
      // Don't fail the registration if form registration update fails
    }

    // Move students from unregistered to registered in RegistrationStatus
    registrationStatus.unregistered = registrationStatus.unregistered.filter(
      s => !allStudentIds.includes(s.studentId)
    );
    
    // Add students to registered list with projectId and form details
    const newRegisteredStudents = allStudentIds.map(studentId => ({
      studentId,
      projectId,
      formName: form.name,
      formId: formId,
      registrationDate: new Date(),
      isRegistered: true
    }));
    registrationStatus.registered.push(...newRegisteredStudents);
    await registrationStatus.save({ session });
    console.log('Registration status updated');

    // Increment registeredGroups for the project
    form.projects[projectIndex].registeredGroups += 1;
    await form.save({ session });
    console.log('Form updated with new registration');

    // Update all students with registration details
    const studentUpdate = await Student.updateMany(
      { studentId: { $in: allStudentIds } },
      {
        $set: {
          projectId: projectId,
          role: 'student',
          projectTitle: project.title,
          formName: form.name,
          formId: formId,
          isRegistered: true,
          registrationDate: new Date()
        }
      },
      { session }
    );
    console.log('Students updated:', studentUpdate);

    await session.commitTransaction();
    console.log('Transaction committed successfully');

    // Format the response data
    const responseData = {
      success: true,
      message: 'Group registration successful',
      data: {
        projectDetails: {
          title: project.title,
          projectId: projectId,
          description: project.description,
          registeredGroups: project.registeredGroups + 1,
          maxGroups: project.maxGroups
        },
        teamDetails: {
          teamSize,
          teamLeader: {
            studentId: teamLeader,
            role: 'student',
            projectId: projectId
          },
          teamMembers: teamMembers.map(memberId => ({
            studentId: memberId,
            role: 'student',
            projectId: projectId
          }))
        },
        registrationDetails: {
          registrationId: registration._id,
          formId: formId,
          year: form.year,
          registeredAt: registration.registeredAt
        }
      }
    };

    res.status(201).json(responseData);
  } catch (error) {
    console.error('Error in registerGroup:', error);
    await session.abortTransaction();
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message
    });
  } finally {
    session.endSession();
  }
};

exports.getGroups = async (req, res) => {
  try {
    const { formId } = req.params;
    const groups = await ProjectGroupRegistration.find({ formId })
      .populate('formId', 'year projects registeredStudents unregisteredStudents')
      .sort('-registeredAt');
    
    res.json({
      success: true,
      data: groups,
      count: groups.length
    });
  } catch (error) {
    console.error('Error fetching groups:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
};

exports.getRegistrationStatus = async (req, res) => {
  try {
    const { formId } = req.params;
    const status = await RegistrationStatus.findOne({ formId });
    
    if (!status) {
      return res.status(404).json({
        success: false,
        message: 'Registration status not found'
      });
    }

    res.json({
      success: true,
      data: {
        registered: status.registered,
        unregistered: status.unregistered
      }
    });
  } catch (error) {
    console.error('Error fetching registration status:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message
    });
  }
};

exports.initializeRegistration = async (req, res) => {
  try {
    const { formId, year } = req.body;
    
    // Get the form
    const form = await ProjectForm.findById(formId);
    if (!form) {
      return res.status(404).json({
        success: false,
        message: 'Project form not found'
      });
    }

    // Get all students for the specified year
    const students = await Student.find({ year });
    const studentIds = students.map(student => student.studentId);

    // Create registration status with all students in unregistered list
    const registrationStatus = new RegistrationStatus({
      formId,
      year,
      formName: form.name,
      unregistered: studentIds.map(studentId => ({
        studentId,
        formId: formId,
        formName: form.name,
        isRegistered: false,
        addedDate: new Date()
      })),
      registered: []
    });

    await registrationStatus.save();

    res.status(201).json({
      success: true,
      message: 'Registration initialized successfully',
      data: {
        totalStudents: studentIds.length,
        unregisteredStudents: studentIds.length,
        registeredStudents: 0
      }
    });
  } catch (error) {
    console.error('Error initializing registration:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message
    });
  }
};

exports.getStudentsByFormId = async (req, res) => {
  try {
    const { formId } = req.params;
    
    // Get the form details
    const form = await ProjectForm.findById(formId);
    if (!form) {
      return res.status(404).json({
        success: false,
        message: 'Form not found'
      });
    }

    // Get registration status
    const registrationStatus = await RegistrationStatus.findOne({ formId });
    if (!registrationStatus) {
      return res.status(404).json({
        success: false,
        message: 'Registration status not found for this form'
      });
    }

    // Get all students for the year
    const students = await Student.find({ year: form.year });
    
    // Create a map of student details for easy lookup
    const studentMap = new Map(
      students.map(student => [
        student.studentId,
        {
          name: student.name,
          studentId: student.studentId,
          year: student.year,
          department: student.department
        }
      ])
    );

    // Process registered students
    const registeredStudents = registrationStatus.registered.map(reg => ({
      ...studentMap.get(reg.studentId),
      projectId: reg.projectId,
      formName: reg.formName,
      registrationDate: reg.registrationDate,
      isRegistered: true
    }));

    // Process unregistered students
    const unregisteredStudents = registrationStatus.unregistered.map(unreg => ({
      ...studentMap.get(unreg.studentId),
      formName: unreg.formName,
      addedDate: unreg.addedDate,
      isRegistered: false
    }));

    // Get all project details for the form
    const projects = form.projects.map(project => ({
      projectId: project.projectId,
      title: project.title,
      description: project.description,
      registeredGroups: project.registeredGroups,
      maxGroups: project.maxGroups
    }));

    res.json({
      success: true,
      data: {
        formDetails: {
          formId: form._id,
          formName: form.name,
          year: form.year,
          totalStudents: students.length,
          registeredCount: registeredStudents.length,
          unregisteredCount: unregisteredStudents.length
        },
        projects,
        registeredStudents,
        unregisteredStudents
      }
    });
  } catch (error) {
    console.error('Error fetching students by form ID:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message
    });
  }
};

exports.getStudentsByFormName = async (req, res) => {
  try {
    const { formName } = req.params;
    
    // Get the form details by name
    const form = await ProjectForm.findOne({ formName });
    if (!form) {
      return res.status(404).json({
        success: false,
        message: 'Form not found'
      });
    }

    // Get registration status
    const registrationStatus = await RegistrationStatus.findOne({ formId: form._id });
    if (!registrationStatus) {
      return res.status(404).json({
        success: false,
        message: 'Registration status not found for this form'
      });
    }

    // Get all students for the year
    const students = await Student.find({ year: form.year });
    
    // Create a map of student details for easy lookup
    const studentMap = new Map(
      students.map(student => [
        student.studentId,
        {
          name: student.name,
          studentId: student.studentId,
          year: student.year,
          department: student.department
        }
      ])
    );

    // Process registered students
    const registeredStudents = registrationStatus.registered.map(reg => ({
      ...studentMap.get(reg.studentId),
      projectId: reg.projectId,
      formName: reg.formName,
      registrationDate: reg.registrationDate,
      isRegistered: true
    }));

    // Process unregistered students
    const unregisteredStudents = registrationStatus.unregistered.map(unreg => ({
      ...studentMap.get(unreg.studentId),
      formName: unreg.formName,
      addedDate: unreg.addedDate,
      isRegistered: false
    }));

    // Get all project details for the form
    const projects = form.projects.map(project => ({
      projectId: project.projectId,
      title: project.title,
      description: project.description,
      registeredGroups: project.registeredGroups,
      maxGroups: project.maxGroups
    }));

    res.json({
      success: true,
      data: {
        formDetails: {
          formId: form._id,
          formName: form.formName,
          year: form.year,
          totalStudents: students.length,
          registeredCount: registeredStudents.length,
          unregisteredCount: unregisteredStudents.length
        },
        projects,
        registeredStudents,
        unregisteredStudents
      }
    });
  } catch (error) {
    console.error('Error fetching students by form name:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message
    });
  }
}; 