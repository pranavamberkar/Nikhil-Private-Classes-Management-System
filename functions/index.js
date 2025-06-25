const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.getUserIdByEmail = functions.https.onCall(async (data, context) => {
  const email = data.email;

  if (!email) {
    throw new functions.https.HttpsError("invalid-argument",
        "Email is required.");
  }

  try {
    // Query Firestore users collection
    const snapshot = await admin.firestore()
        .collection("users") // Make sure collection name is correct
        .where("email", "==", email)
        .limit(1)
        .get();

    if (snapshot.empty) {
      throw new functions.https.HttpsError("not-found",
          "No matching user found.");
    }

    const userDoc = snapshot.docs[0].data();
    return {userId: userDoc.uid};
  } catch (error) {
    throw new functions.https.HttpsError("unknown", error.message);
  }
});
