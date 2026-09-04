const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

/**
 * 1. Push notification on appointment creation (Proposal Page 11 & 20)
 */
exports.onAppointmentCreated = onDocumentCreated("appointments/{appointmentId}", async (event) => {
  const snapshot = event.data;
  if (!snapshot) return;

  const appt = snapshot.data();
  const patientPhone = appt.patientPhone;

  // Notification Payload
  const title = "Appointment Confirmed";
  const body = `Your appointment with ${appt.doctorName} at ${appt.date} (${appt.timeSlot}) is scheduled. Token #${appt.tokenNumber}`;

  // Log in notifications collection
  await db.collection("notifications").add({
    patientPhone: patientPhone,
    patientId: appt.patientId,
    title: title,
    body: body,
    type: "appointment_created",
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
    read: false,
  });

  console.log(`[FCM] Notification sent for appointment ${event.params.appointmentId}`);
});

/**
 * 2. Push notification on appointment status change (Proposal Page 11)
 */
exports.onAppointmentStatusUpdated = onDocumentUpdated("appointments/{appointmentId}", async (event) => {
  const beforeData = event.data.before.data();
  const afterData = event.data.after.data();

  if (beforeData.status === afterData.status) return;

  let title = "Appointment Update";
  let body = `Your appointment status with ${afterData.doctorName} is now: ${afterData.status.toUpperCase()}`;

  if (afterData.status === "inConsultation") {
    title = "Consultation Started";
    body = `Please proceed to ${afterData.doctorName}'s cabin (Token #${afterData.tokenNumber}).`;
  } else if (afterData.status === "completed") {
    title = "Consultation Completed";
    body = `Your visit with ${afterData.doctorName} is complete. Your prescription is ready in the app.`;
  }

  await db.collection("notifications").add({
    patientPhone: afterData.patientPhone,
    patientId: afterData.patientId,
    title: title,
    body: body,
    type: "status_change",
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
    read: false,
  });
});

/**
 * 3. Daily Automated Follow-Up Reminders Scheduler (Proposal Page 10 & 20)
 * Runs every day at 08:00 AM IST
 */
exports.scheduledFollowUpReminders = onSchedule({
  schedule: "0 8 * * *",
  timeZone: "Asia/Kolkata",
}, async (event) => {
  const tomorrow = new Date();
  tomorrow.setDate(tomorrow.getDate() + 1);
  const tomorrowStr = tomorrow.toISOString().split("T")[0]; // YYYY-MM-DD format

  const snapshot = await db.collection("prescriptions")
    .where("followUpDate", "==", tomorrowStr)
    .get();

  const batch = db.batch();

  snapshot.forEach((doc) => {
    const rx = doc.data();
    const notificationRef = db.collection("notifications").doc();
    batch.set(notificationRef, {
      patientId: rx.patientId,
      title: "Follow-Up Reminder",
      body: `Reminder: Your follow-up appointment with ${rx.doctorName} is tomorrow (${rx.followUpReason || "Review"}).`,
      type: "followup_reminder",
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      read: false,
    });
  });

  await batch.commit();
  console.log(`[Follow-Up Cron] Sent ${snapshot.size} follow-up reminders.`);
});

/**
 * 4. Existing Patient Account Linking Function (Proposal Section 7, Page 4 & 5)
 */
exports.linkPatientAccount = onCall(async (request) => {
  const { phone, userId } = request.data;
  if (!phone || !userId) {
    throw new HttpsError("invalid-argument", "Phone and userId are required.");
  }

  const patientQuery = await db.collection("patients")
    .where("mobile", "==", phone)
    .limit(1)
    .get();

  if (!patientQuery.empty) {
    const patientDoc = patientQuery.docs[0];
    const patientData = patientDoc.data();

    // Link user profile with existing patient ID
    await db.collection("users").doc(userId).set({
      patientId: patientData.patientId,
      linkedMobile: phone,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });

    return {
      linked: true,
      patientId: patientData.patientId,
      name: patientData.name,
    };
  }

  return { linked: false };
});
