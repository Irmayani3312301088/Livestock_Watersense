const isAdmin = (req, res, next) => {
  if (req.user.role?.toLowerCase() !== 'admin') {
    return res.status(403).json({ success: false, message: 'Akses ditolak. Hanya admin.' });
  }
  next();
};

module.exports = isAdmin;
