const express = require('express');
const router = express.Router();
const notificationController = require('../controllers/notificationController');
const { verifyToken } = require('../middlewares/authMiddleware');

router.post('/notifications', verifyToken, notificationController.sendNotification);
router.get('/notifications', verifyToken, notificationController.getAllNotifications);
router.delete('/notifications', verifyToken, notificationController.deleteAllNotifications);
router.patch('/notifications/read-all', verifyToken, notificationController.markAllAsRead);

module.exports = router;
