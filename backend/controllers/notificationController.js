const Notification = require('../models/notificationModel');

exports.deleteAllNotifications = async (req, res) => {
  try {
    await Notification.destroy({ where: {} });
    res.status(200).json({ message: 'Semua notifikasi dihapus.' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Gagal menghapus notifikasi.' });
  }
};

exports.markAllAsRead = async (req, res) => {
  try {
    await Notification.update({ is_read: true }, { where: {} });
    res.status(200).json({ message: 'Semua notifikasi ditandai sudah dibaca.' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Gagal menandai notifikasi.' });
  }
};

exports.sendNotification = async (req, res) => {
  const { title, message, type } = req.body;

  try {
    await Notification.create({ title, message, type });
    res.status(201).json({ message: 'Notifikasi dikirim.' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Gagal mengirim notifikasi.' });
  }
};

exports.getAllNotifications = async (req, res) => {
  try {
    const result = await Notification.findAll({
      order: [['created_at', 'DESC']],
    });
    res.status(200).json(result);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Gagal Mengambil Notifikasi.' });
  }
};
