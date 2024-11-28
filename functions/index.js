const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.sendNotification = functions.https.onCall(async (data, context) => {
    const { topic, notification, data: messageData } = data;

    const message = {
        notification,
        data: messageData,
        topic,
    };

    try {
        const response = await admin.messaging().send(message);
        return { success: true, response };
    } catch (error) {
        console.error('Error sending notification:', error);
        throw new functions.https.HttpsError('internal', 'Error sending notification');
    }
}); 