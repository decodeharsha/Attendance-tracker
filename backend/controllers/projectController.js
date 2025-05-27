const Project = require('../models/project');

exports.createProject = async (req, res) => {
  try {
    const { projectId, title, description, maxGroups, minMembers, maxMembers } = req.body;

    // Check if project with same ID already exists
    const existingProject = await Project.findOne({ projectId });
    if (existingProject) {
      return res.status(400).json({ message: 'Project ID already exists' });
    }

    const project = new Project({
      projectId,
      title,
      description,
      maxGroups,
      minMembers,
      maxMembers
    });

    await project.save();
    res.status(201).json(project);
  } catch (error) {
    console.error('Error creating project:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

exports.getProjects = async (req, res) => {
  try {
    const projects = await Project.find({ isDeleted: false }).sort({ createdAt: -1 });
    res.json(projects);
  } catch (error) {
    console.error('Error fetching projects:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

exports.updateProject = async (req, res) => {
  try {
    const { projectId } = req.params;
    const { title, description, maxGroups, minMembers, maxMembers } = req.body;

    const project = await Project.findOne({ projectId, isDeleted: false });
    if (!project) {
      return res.status(404).json({ message: 'Project not found' });
    }

    project.title = title;
    project.description = description;
    project.maxGroups = maxGroups;
    project.minMembers = minMembers;
    project.maxMembers = maxMembers;

    await project.save();
    res.json(project);
  } catch (error) {
    console.error('Error updating project:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

exports.softDeleteProject = async (req, res) => {
  try {
    const { projectId } = req.params;

    const project = await Project.findOne({ projectId, isDeleted: false });
    if (!project) {
      return res.status(404).json({ message: 'Project not found' });
    }

    project.isDeleted = true;
    await project.save();
    res.json({ message: 'Project deleted successfully' });
  } catch (error) {
    console.error('Error deleting project:', error);
    res.status(500).json({ message: 'Server error' });
  }
}; 