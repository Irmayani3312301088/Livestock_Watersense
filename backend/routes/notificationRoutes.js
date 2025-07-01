const express = require('express');
const router =  express.Router();
const notificationController = require('../controllers/notificationController');

router.post('/notifications', notificationController.sendNotification);
router.get('/notifications', notificationController.getAllNotifications);
router.delete('/notifications', notificationController.deleteAllNotifications);
router.patch('/notifications/read-all', notificationController.markAllAsRead);

module.exports = router;
