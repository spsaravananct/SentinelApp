const {onRequest} = require("firebase-functions/v2/https");
const {logger} = require("firebase-functions");
const admin = require("firebase-admin");

// Initialize Firebase Admin
admin.initializeApp();

// OneSignal Configuration - Replace with your credentials
const ONESIGNAL_APP_ID = "f7eb2ffc-7c5a-4c4f-9bdb-2345f7ac9ec7";
const ONESIGNAL_REST_API_KEY = "os_v2_app_67vs77d4ljge7g63enc7ple6y6f26zwzcmwergvdxwn6tjo2d4amev4saorj7qsovkxm3zk6hwt6zgsz5ve5hs24pfhj44wcukpyusi";

// Function to send OneSignal notification
async function sendOneSignalNotification(playerIds, title, message, data = {}) {
  try {
    const fetch = (await import('node-fetch')).default;
    
    const notification = {
      app_id: ONESIGNAL_APP_ID,
      include_player_ids: playerIds,
      headings: { en: title },
      contents: { en: message },
      data: data,
      priority: 10,
      sound: "emergency_alert.wav",
    };

    const response = await fetch('https://onesignal.com/api/v1/notifications', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Basic ${ONESIGNAL_REST_API_KEY}`,
      },
      body: JSON.stringify(notification),
    });

    const result = await response.json();
    logger.info("OneSignal response:", result);
    
    return {
      success: response.ok,
      result: result,
    };
  } catch (error) {
    logger.error("Error sending OneSignal notification:", error);
    return {
      success: false,
      error: error.message,
    };
  }
}

// 🚨 Emergency Alert Function
exports.sendEmergencyAlert = onRequest(async (req, res) => {
  // Enable CORS
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'GET, POST');
  res.set('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }

  try {
    const {
      userPlayerId,
      emergencyContacts,
      location,
      message,
      userName
    } = req.body;

    logger.info("Emergency alert request:", req.body);

    // Validate required fields
    if (!userPlayerId || !emergencyContacts || !Array.isArray(emergencyContacts)) {
      res.status(400).json({
        success: false,
        error: "Missing required fields: userPlayerId, emergencyContacts"
      });
      return;
    }

    // Prepare notification data
    const title = "🚨 EMERGENCY ALERT";
    const notificationMessage = message || `${userName || 'Someone'} has activated an emergency alert. Please check on them immediately!`;
    
    const notificationData = {
      type: "emergency",
      userPlayerId: userPlayerId,
      location: location || "Location not available",
      timestamp: new Date().toISOString(),
      userName: userName || "Unknown User"
    };

    // Send to emergency contacts
    const playerIds = emergencyContacts.filter(contact => contact.playerId).map(contact => contact.playerId);
    
    if (playerIds.length === 0) {
      res.status(400).json({
        success: false,
        error: "No valid player IDs found in emergency contacts"
      });
      return;
    }

    logger.info(`Sending emergency alert to ${playerIds.length} contacts:`, playerIds);

    const result = await sendOneSignalNotification(
      playerIds,
      title,
      notificationMessage,
      notificationData
    );

    // Also send confirmation to the user who triggered the alert
    await sendOneSignalNotification(
      [userPlayerId],
      "🆘 Emergency Alert Sent",
      `Your emergency alert has been sent to ${playerIds.length} emergency contacts.`,
      { type: "emergency_confirmation" }
    );

    res.json({
      success: result.success,
      message: `Emergency alert sent to ${playerIds.length} contacts`,
      onesignalResult: result.result,
      contactsNotified: playerIds.length
    });

  } catch (error) {
    logger.error("Error in sendEmergencyAlert:", error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// 🛡️ Safety Check Function
exports.sendSafetyCheckAlert = onRequest(async (req, res) => {
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'GET, POST');
  res.set('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }

  try {
    const {
      userPlayerId,
      emergencyContacts,
      status,
      location,
      userName
    } = req.body;

    const title = "🛡️ Safety Check-In";
    const message = `${userName || 'Someone'} has checked in safely. Status: ${status}. Location: ${location || 'Not provided'}`;
    
    const data = {
      type: "safety_check",
      userPlayerId: userPlayerId,
      status: status,
      location: location,
      timestamp: new Date().toISOString()
    };

    const playerIds = emergencyContacts.filter(contact => contact.playerId).map(contact => contact.playerId);
    
    const result = await sendOneSignalNotification(playerIds, title, message, data);

    res.json({
      success: result.success,
      message: `Safety check sent to ${playerIds.length} contacts`,
      onesignalResult: result.result
    });

  } catch (error) {
    logger.error("Error in sendSafetyCheckAlert:", error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// 📍 Location Update Function
exports.sendLocationUpdate = onRequest(async (req, res) => {
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'GET, POST');
  res.set('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }

  try {
    const {
      userPlayerId,
      emergencyContacts,
      location,
      locationName,
      userName
    } = req.body;

    const title = "📍 Location Update";
    const message = `${userName || 'Someone'} has shared their location: ${locationName || location || 'Location shared'}`;
    
    const data = {
      type: "location_update",
      userPlayerId: userPlayerId,
      location: location,
      locationName: locationName,
      timestamp: new Date().toISOString()
    };

    const playerIds = emergencyContacts.filter(contact => contact.playerId).map(contact => contact.playerId);
    
    const result = await sendOneSignalNotification(playerIds, title, message, data);

    res.json({
      success: result.success,
      message: `Location update sent to ${playerIds.length} contacts`,
      onesignalResult: result.result
    });

  } catch (error) {
    logger.error("Error in sendLocationUpdate:", error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// 🔋 Low Battery Alert Function
exports.sendLowBatteryAlert = onRequest(async (req, res) => {
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'GET, POST');
  res.set('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }

  try {
    const {
      userPlayerId,
      emergencyContacts,
      batteryLevel,
      location,
      userName
    } = req.body;

    const title = "🔋 Low Battery Alert";
    const message = `${userName || 'Someone'}'s device battery is at ${batteryLevel}%. Last known location: ${location || 'Unknown'}`;
    
    const data = {
      type: "low_battery",
      userPlayerId: userPlayerId,
      batteryLevel: batteryLevel,
      location: location,
      timestamp: new Date().toISOString()
    };

    const playerIds = emergencyContacts.filter(contact => contact.playerId).map(contact => contact.playerId);
    
    const result = await sendOneSignalNotification(playerIds, title, message, data);

    res.json({
      success: result.success,
      message: `Low battery alert sent to ${playerIds.length} contacts`,
      onesignalResult: result.result
    });

  } catch (error) {
    logger.error("Error in sendLowBatteryAlert:", error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// ✅ Test Function
exports.testNotification = onRequest(async (req, res) => {
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'GET, POST');
  res.set('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }

  try {
    const { playerId } = req.body;

    if (!playerId) {
      res.status(400).json({
        success: false,
        error: "Missing playerId"
      });
      return;
    }

    const result = await sendOneSignalNotification(
      [playerId],
      "🧪 Test Notification",
      "Your Firebase Cloud Function is working! OneSignal integration successful.",
      { type: "test" }
    );

    res.json({
      success: result.success,
      message: "Test notification sent",
      onesignalResult: result.result
    });

  } catch (error) {
    logger.error("Error in testNotification:", error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});