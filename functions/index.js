const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { initializeApp } = require('firebase-admin/app');
const { getMessaging } = require('firebase-admin/messaging');

initializeApp();

/**
 * sendBroadcastNotification
 *
 * Triggers when the super admin creates a new document in /broadcasts.
 * Sends an FCM notification to the 'all_users' topic so every
 * subscribed device receives it instantly.
 *
 * Deploy with:
 *   cd functions && npm install
 *   firebase deploy --only functions
 */
exports.sendBroadcastNotification = onDocumentCreated(
  'broadcasts/{broadcastId}',
  async (event) => {
    const data = event.data.data();
    const title = data?.title ?? '';
    const body  = data?.body  ?? '';

    if (!title || !body) {
      await event.data.ref.update({ status: 'error', error: 'missing title or body' });
      return;
    }

    const message = {
      topic: 'all_users',
      notification: { title, body },
      apns: {
        payload: {
          aps: { sound: 'default', badge: 1 },
        },
      },
      android: {
        notification: {
          sound: 'default',
          channelId: 'broadcasts',
        },
      },
    };

    try {
      const response = await getMessaging().send(message);
      await event.data.ref.update({
        status: 'sent',
        fcmMessageId: response,
        sentAt: new Date(),
      });
      console.log('Broadcast sent:', response);
    } catch (err) {
      console.error('Broadcast failed:', err);
      await event.data.ref.update({
        status: 'error',
        error: err.message,
      });
    }
  }
);
