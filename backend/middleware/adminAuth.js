// Middleware to allow only admin users
module.exports = (req, res, next) => {
  if (!req.user || req.user.role !== 'admin') {
    return res.status(403).json({ message: 'Only admin can perform this action.' });
  }
  next();
};
